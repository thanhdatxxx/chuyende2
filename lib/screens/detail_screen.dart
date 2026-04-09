import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'payment_screen.dart';
import '../services/auth_service.dart';
import '../widgets/ui_effects.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _account = const {};
  int _displayCode = 123001;
  String _accountDocId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final raw = args['account'];
      if (raw is Map<String, dynamic>) {
        final safeData = Map<String, dynamic>.from(raw);
        safeData.remove('taikhoan');
        safeData.remove('matkhau');
        _account = safeData;
      }
      _displayCode = (args['displayCode'] is int) ? args['displayCode'] as int : 123001;
      _accountDocId = (args['docId'] ?? '').toString();
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _asText(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? fallback : text;
  }

  String get _imageUrl => _asText(_account['image_url'], fallback: '');

  bool _isSoldStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized.contains('đã bán') || normalized.contains('da ban') || normalized == 'sold';
  }

  String _statusLabelVi(String rawStatus) {
    if (_isSoldStatus(rawStatus)) return 'Đã bán';

    final normalized = rawStatus.trim().toLowerCase();
    if (normalized == 'available' || normalized == 'ready' || normalized == 'in_stock') {
      return 'Sẵn sàng';
    }
    if (normalized == 'sẵn sàng' || normalized == 'san sang') return 'Sẵn sàng';
    return 'Sẵn sàng';
  }

  List<int>? _priceBucket(double price) {
    final value = price.toInt();
    const buckets = <List<int>>[
      [100000, 500000],
      [500001, 1500000],
      [1500001, 5000000],
      [5000001, 10000000],
      [10000001, 20000000],
      [20000001, 50000000],
    ];

    for (final bucket in buckets) {
      if (value >= bucket[0] && value <= bucket[1]) return bucket;
    }
    return null;
  }

  String _normalizeRankKey(String rawRank) {
    final normalized = rawRank.trim().toLowerCase();
    if (normalized.contains('thách đấu') || normalized.contains('thach dau')) return 'thach_dau';
    if (normalized.contains('chiến thần') || normalized.contains('chien than')) return 'chien_than';
    if (normalized.contains('chiến tướng') || normalized.contains('chien tuong')) return 'chien_tuong';
    return normalized;
  }

  List<String> _fallbackRankKeys(String rawRank) {
    final current = _normalizeRankKey(rawRank);
    if (current == 'chien_tuong') {
      return ['chien_tuong', 'chien_than', 'thach_dau'];
    }
    if (current == 'chien_than') {
      return ['chien_than', 'thach_dau', 'chien_tuong'];
    }
    if (current == 'thach_dau') {
      return ['thach_dau', 'chien_than', 'chien_tuong'];
    }
    return current.isEmpty ? <String>[] : <String>[current];
  }

  Future<void> _handleBuyFromDetail() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để mua tài khoản!')),
      );
      return;
    }

    final price = _asDouble(_account['price']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận mua tài khoản'),
        content: Text('Bạn có muốn mua tài khoản #$_displayCode với giá ${price.toInt()}đ không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mua ngay')),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: PaymentFlowArgs(
        accountId: _accountDocId,
        displayCode: _displayCode,
        price: price,
        rank: _asText(_account['rank']),
        heroCount: _asText(_account['hero_count'], fallback: '0'),
        skinCount: _asText(_account['skin_count'], fallback: '0'),
      ),
    );
  }

  void _openFullImage() {
    if (_imageUrl.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                maxScale: 10,
                minScale: 0.8,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(100),
                trackpadScrollCausesScale: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EffectPageScaffold(
      backgroundOpacity: 0.78,
      topMenu: _buildTopMenu(),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final topContent = constraints.maxWidth > 900
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildImageSection()),
                          const SizedBox(width: 30),
                          Expanded(flex: 2, child: _buildInfoSection()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildImageSection(),
                          const SizedBox(height: 30),
                          _buildInfoSection(),
                        ],
                      );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    topContent,
                    const SizedBox(height: 20),
                    _buildSuggestedAccounts(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/'),
                child: const AnimatedShopName(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Consumer<AuthService>(
                      builder: (context, authService, _) {
                  if (!authService.isLoggedIn) {
                    return Row(
                      children: [
                        HoverMenuItem(title: 'Đăng ký', onTap: () => Navigator.pushNamed(context, '/register')),
                        const SizedBox(width: 25),
                        HoverMenuItem(title: 'Đăng nhập', onTap: () => Navigator.pushNamed(context, '/login')),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      HoverMenuItem(title: 'Trang chủ', icon: Icons.home, onTap: () => Navigator.pushNamed(context, '/')),
                      const SizedBox(width: 25),
                      HoverMenuItem(
                        title: 'Lịch sử giao dịch',
                        icon: Icons.history,
                        onTap: () => Navigator.pushNamed(context, '/history'),
                      ),
                      const SizedBox(width: 25),
                      const DepositMenuButton(),
                      const SizedBox(width: 30),
                      Text(
                        authService.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFFF7ED), fontSize: 14),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: PopupMenuButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          position: PopupMenuPosition.under,
                          offset: const Offset(12, 10),
                          constraints: const BoxConstraints(minWidth: 190),
                          color: Colors.white.withValues(alpha: 0.16),
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          icon: const Icon(Icons.account_circle, color: Color(0xFFF97316), size: 30),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Thông tin cá nhân', style: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600)),
                              onTap: () => Navigator.pushNamed(context, '/user-detail'),
                            ),
                            PopupMenuItem(
                              child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600)),
                              onTap: () {
                                context.read<AuthService>().logout();
                                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đăng xuất thành công!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return GestureDetector(
      onTap: _openFullImage,
      child: Container(
      width: double.infinity,
      height: isMobile ? 280 : 430,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _imageUrl.isEmpty
            ? const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 42))
            : Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 42),
                ),
              ),
      ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final rank = _asText(_account['rank']);
    final skins = _asText(_account['skin_count'], fallback: '0');
    final heroes = _asText(_account['hero_count'], fallback: '0');
    final status = _asText(_account['status'], fallback: 'Sẵn sàng');
    final description = _asText(_account['description'], fallback: 'Chưa có mô tả');
    final price = _asDouble(_account['price']);
    final sold = _isSoldStatus(status);
    final statusVi = _statusLabelVi(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chi tiết tài khoản #$_displayCode', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildInfoRow('Rank hiện tại:', rank, isBold: true),
              _buildInfoRow('Số lượng trang phục:', skins),
              _buildInfoRow('Số lượng tướng:', heroes),
              _buildInfoRow('Trạng thái:', statusVi),
              _buildDescriptionField('Mô tả:', description),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.28)),
          ),
          child: Column(
            children: [
              _buildPriceRow('Giá tài khoản:', price),
              const SizedBox(height: 10),
              _buildPriceRow('Thanh toán ATM/MoMo:', price, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: sold ? null : _handleBuyFromDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: sold ? Colors.grey : const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              sold ? 'TÀI KHOẢN ĐÃ BÁN' : 'MUA NGAY TÀI KHOẢN',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(
          '${price.toInt()}đ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 14),
          Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35),
          ),
        ],
      ),
    );
  }

  int _extractDisplayCode(Map<String, dynamic> account, int fallback) {
    final raw = account['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  void _openSuggestedAccount(String docId, Map<String, dynamic> rawAccount, int fallbackCode) {
    final safeData = Map<String, dynamic>.from(rawAccount);
    safeData.remove('taikhoan');
    safeData.remove('matkhau');

    Navigator.pushReplacementNamed(
      context,
      '/detail',
      arguments: {
        'docId': docId,
        'displayCode': _extractDisplayCode(safeData, fallbackCode),
        'account': safeData,
      },
    );
  }

  Widget _buildSuggestedAccounts() {
    final currentPrice = _asDouble(_account['price']);
    final bucket = _priceBucket(currentPrice);
    final currentRank = _asText(_account['rank'], fallback: '');
    final rankFallbackKeys = _fallbackRankKeys(currentRank);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đề xuất 5 tài khoản khác',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Giữ chuột và kéo ngang sang phải để xem thêm',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('accounts').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Không thể tải danh sách đề xuất.'),
                );
              }

              final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];
              final activeCandidates = docs
                  .where((doc) => doc.id != _accountDocId)
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {'docId': doc.id, 'data': data};
                  })
                  .where((item) {
                    final data = item['data'] as Map<String, dynamic>;
                    final status = _asText(data['status'], fallback: '');
                    if (_isSoldStatus(status)) return false;
                    return true;
                  })
                  .toList();

              final bucketCandidates = activeCandidates.where((item) {
                if (bucket == null) return false;
                final data = item['data'] as Map<String, dynamic>;
                final price = _asDouble(data['price']);
                return price >= bucket[0] && price <= bucket[1];
              }).toList();

              List<Map<String, Object>> candidates;
              if (bucketCandidates.isNotEmpty) {
                candidates = bucketCandidates.cast<Map<String, Object>>();
                candidates.sort((a, b) {
                  final dataA = a['data'] as Map<String, dynamic>;
                  final dataB = b['data'] as Map<String, dynamic>;
                  final distanceA = (_asDouble(dataA['price']) - currentPrice).abs();
                  final distanceB = (_asDouble(dataB['price']) - currentPrice).abs();
                  return distanceA.compareTo(distanceB);
                });
              } else {
                candidates = activeCandidates
                    .where((item) {
                      if (rankFallbackKeys.isEmpty) return false;
                      final data = item['data'] as Map<String, dynamic>;
                      final rankKey = _normalizeRankKey(_asText(data['rank'], fallback: ''));
                      return rankFallbackKeys.contains(rankKey);
                    })
                    .map((item) => Map<String, Object>.from(item))
                    .toList();

                candidates.sort((a, b) {
                  final dataA = a['data'] as Map<String, dynamic>;
                  final dataB = b['data'] as Map<String, dynamic>;
                  final rankA = _normalizeRankKey(_asText(dataA['rank'], fallback: ''));
                  final rankB = _normalizeRankKey(_asText(dataB['rank'], fallback: ''));
                  final rankIndexA = rankFallbackKeys.indexOf(rankA);
                  final rankIndexB = rankFallbackKeys.indexOf(rankB);

                  if (rankIndexA != rankIndexB) {
                    final safeA = rankIndexA == -1 ? 999 : rankIndexA;
                    final safeB = rankIndexB == -1 ? 999 : rankIndexB;
                    return safeA.compareTo(safeB);
                  }

                  final distanceA = (_asDouble(dataA['price']) - currentPrice).abs();
                  final distanceB = (_asDouble(dataB['price']) - currentPrice).abs();
                  return distanceA.compareTo(distanceB);
                });
              }

              final suggestions = candidates.take(5).toList();
              if (suggestions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Hiện chưa có tài khoản đề xuất.'),
                );
              }

              const spacing = 12.0;
              const cardWidth = 240.0;

              return ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(suggestions.length, (index) {
                    final item = suggestions[index];
                    final docId = item['docId'] as String;
                    final data = Map<String, dynamic>.from(item['data'] as Map<String, dynamic>);
                    final rank = _asText(data['rank']);
                    final heroes = _asText(data['hero_count'], fallback: '0');
                    final skins = _asText(data['skin_count'], fallback: '0');
                    final price = _asDouble(data['price']);
                    final status = _asText(data['status'], fallback: 'Sẵn sàng');
                    final sold = _isSoldStatus(status);
                    final statusVi = _statusLabelVi(status);
                    final imageUrl = _asText(data['image_url'], fallback: '');

                    return Padding(
                      padding: EdgeInsets.only(right: index == suggestions.length - 1 ? 0 : spacing),
                      child: SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openSuggestedAccount(docId, data, 123001 + index),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 128,
                                    width: double.infinity,
                                    color: const Color(0xFF0F172A),
                                    child: imageUrl.isEmpty
                                        ? const Icon(Icons.broken_image, color: Colors.white70, size: 32)
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.low,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white70, size: 32),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Acc #${_extractDisplayCode(data, 123001 + index)} - $rank',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tướng: $heroes | Skin: $skins',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                ),
                                Text(
                                  '${price.toInt()}đ',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFFF97316), fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        statusVi,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: sold ? Colors.red.shade600 : Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _openSuggestedAccount(docId, data, 123001 + index),
                                      child: const Text('Xem'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
