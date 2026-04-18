import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/ui_effects.dart';
import '../widgets/home_footer.dart';
import '../widgets/top_menu.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatMoney(double amount) {
    final digits = amount.toInt().toString();
    final withSeparator = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '$withSeparator đ';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final dt = timestamp.toDate();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  bool _isSoldStatus(dynamic value) {
    final status = (value ?? '').toString().trim().toLowerCase();
    return status.contains('da ban') || status.contains('đã bán');
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<Map<String, Map<String, dynamic>>> _loadSoldAccounts(String userName) async {
    Future<QuerySnapshot<Map<String, dynamic>>> queryCollection(String name) {
      return _firestore.collection(name).where('sold_to', isEqualTo: userName).get();
    }

    var soldQuery = await queryCollection('accounts');
    if (soldQuery.docs.isEmpty) {
      soldQuery = await queryCollection('account');
    }

    final result = <String, Map<String, dynamic>>{};
    for (final doc in soldQuery.docs) {
      final data = doc.data();
      if (!_isSoldStatus(data['status'])) continue;
      result[doc.id] = data;
    }
    return result;
  }

  Future<void> _showTransactionDetail(String historyId, dynamic accountCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xem chi tiết'),
        content: const Text('Thông tin tài khoản/mật khẩu là dữ liệu nhạy cảm. Bạn có muốn tiếp tục?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xem')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/history-transaction-detail',
      arguments: {
        'historyId': historyId,
        'accountCode': _asInt(accountCode),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1320),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LỊCH SỬ GIAO DỊCH',
                  style: TextStyle(
                    color: Color(0xFFF97316),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 18),
                StreamBuilder<QuerySnapshot>(
                  stream: auth.isLoggedIn
                      ? _firestore
                      .collection('history')
                      .where('user_name', isEqualTo: auth.userName)
                      .snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    if (!auth.isLoggedIn) {
                      return _emptyHistoryBox('Vui lòng đăng nhập để xem lịch sử giao dịch.', isMobile);
                    }
                    if (snapshot.hasError) {
                      return _emptyHistoryBox('Không thể tải lịch sử giao dịch. Vui lòng thử lại sau.', isMobile);
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rawDocs = snapshot.data?.docs ?? [];
                    final docs = rawDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = (data['type'] ?? 'purchase').toString().trim().toLowerCase();
                      return type == 'purchase';
                    }).toList()
                      ..sort((a, b) {
                        final aTime = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                        final bTime = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });

                    return FutureBuilder<Map<String, Map<String, dynamic>>>(
                      future: _loadSoldAccounts(auth.userName),
                      builder: (context, soldSnapshot) {
                        if (soldSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final soldMap = soldSnapshot.data ?? const <String, Map<String, dynamic>>{};
                        if (docs.isEmpty && soldMap.isEmpty) {
                          return _emptyHistoryBox('Bạn chưa có lịch sử mua nick nào.', isMobile);
                        }

                        final items = <Map<String, dynamic>>[];
                        final accountIdsInHistory = <String>{};

                        for (var i = 0; i < docs.length; i++) {
                          final doc = docs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final accountId = (data['account_id'] ?? '').toString();
                          if (accountId.isNotEmpty) {
                            accountIdsInHistory.add(accountId);
                          }
                          items.add({
                            'history_id': doc.id,
                            'account_id': accountId,
                            'transaction_code': (data['transaction_code'] as num?)?.toInt() ?? (300001 + i),
                            'account_code': (data['account_code'] ?? '-').toString(),
                            'amount': _asDouble(data['amount']),
                            'created_at': data['created_at'] as Timestamp?,
                            'from_history': true,
                          });
                        }

                        var fallbackIndex = items.length;
                        soldMap.forEach((accountId, soldData) {
                          if (accountIdsInHistory.contains(accountId)) return;
                          items.add({
                            'history_id': '',
                            'account_id': accountId,
                            'transaction_code': 300001 + fallbackIndex,
                            'account_code': (soldData['account_code'] ?? '-').toString(),
                            'amount': _asDouble(soldData['price']),
                            'created_at': soldData['sold_at'] as Timestamp?,
                            'from_history': false,
                          });
                          fallbackIndex++;
                        });

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.7)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.orange.shade100),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final accountId = (item['account_id'] ?? '').toString();
                              final soldData = soldMap[accountId];
                              final statusText = (soldData?['status'] ?? 'Đã bán').toString();

                              return _AnimatedHistoryItem(
                                vsync: this,
                                index: index,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  title: Text(
                                    'Mã giao dịch #${item['transaction_code']} - Nick #${item['account_code']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Giá: ${_formatMoney(item['amount'] as double)} | Thời gian: ${_formatDate(item['created_at'] as Timestamp?)} | Trạng thái: $statusText',
                                  ),
                                  trailing: (item['from_history'] == true && (item['history_id'] as String).isNotEmpty)
                                      ? ElevatedButton(
                                    onPressed: () => _showTransactionDetail(
                                      item['history_id'] as String,
                                      item['account_code'],
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF97316),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Xem chi tiết giao dịch'),
                                  )
                                      : const Text('Dữ liệu bổ sung', style: TextStyle(fontSize: 12)),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 50),
                const HomeFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyHistoryBox(String title, bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 260 : 330,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.7)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 20 : 28,
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Icon(Icons.history_toggle_off, size: isMobile ? 68 : 86, color: Colors.orange.shade400),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHistoryItem extends StatefulWidget {
  final TickerProvider vsync;
  final int index;
  final Widget child;

  const _AnimatedHistoryItem({
    required this.vsync,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedHistoryItem> createState() => _AnimatedHistoryItemState();
}

class _AnimatedHistoryItemState extends State<_AnimatedHistoryItem> {
  late AnimationController animationController;
  late Animation<double> fadeInAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      vsync: widget.vsync,
    );
    fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );
    slideAnimation = Tween<Offset>(begin: const Offset(0.3, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeInAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: widget.child,
      ),
    );
  }
}
