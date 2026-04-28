import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'payment_screen.dart';
import '../services/auth_service.dart';
import '../widgets/home_footer.dart';
import '../widgets/ui_effects.dart';
import '../widgets/top_menu.dart';

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
      
      final passedCode = _asInt(args['displayCode']);
      final accountId = _asInt(_account['id']);
      _displayCode = passedCode ?? accountId ?? 123001;
      
      _accountDocId = (args['docId'] ?? '').toString();
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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
    if (current == 'chien_tuong') return ['chien_tuong', 'chien_than', 'thach_dau'];
    if (current == 'chien_than') return ['chien_than', 'thach_dau', 'chien_tuong'];
    if (current == 'thach_dau') return ['thach_dau', 'chien_than', 'chien_tuong'];
    return current.isEmpty ? <String>[] : <String>[current];
  }

  Future<void> _handleBuyFromDetail() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để mua!')));
      return;
    }
    final price = _asDouble(_account['price']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận mua'),
        content: Text('Mua tài khoản #$_displayCode giá ${price.toInt()}đ?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mua ngay'))],
      ),
    );
    if (confirmed == true) {
      Navigator.pushNamed(context, '/payment', arguments: PaymentFlowArgs(accountId: _accountDocId, displayCode: _displayCode, price: price, rank: _asText(_account['rank']), heroCount: _asText(_account['hero_count'], fallback: '0'), skinCount: _asText(_account['skin_count'], fallback: '0')));
    }
  }

  void _openSuggestedAccount(String docId, Map<String, dynamic> rawAccount, int fallbackCode) {
    final safeData = Map<String, dynamic>.from(rawAccount);
    safeData.remove('taikhoan'); safeData.remove('matkhau');
    Navigator.pushReplacementNamed(context, '/detail', arguments: {
      'docId': docId, 
      'displayCode': _asInt(safeData['id']) ?? fallbackCode, 
      'account': safeData
    });
  }

  @override
  Widget build(BuildContext context) {
    return EffectPageScaffold(
      backgroundOpacity: 0.78,
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      return constraints.maxWidth > 900
                          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _buildImageSection()), const SizedBox(width: 30), Expanded(flex: 2, child: _buildInfoSection())])
                          : Column(children: [_buildImageSection(), const SizedBox(height: 30), _buildInfoSection()]);
                    }),
                    const SizedBox(height: 40),
                    _buildSuggestedAccounts(), 
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedAccounts() {
    final currentPrice = _asDouble(_account['price']);
    final bucket = _priceBucket(currentPrice);
    final currentRank = _asText(_account['rank'], fallback: '');
    final rankFallbackKeys = _fallbackRankKeys(currentRank);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đề xuất 5 tài khoản tương tự', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Giữ chuột và kéo ngang sang phải để xem thêm', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('accounts').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final docs = snapshot.data!.docs;
              final List<Map<String, dynamic>> activeCandidates = docs
                  .where((doc) => doc.id != _accountDocId)
                  .map<Map<String, dynamic>>((doc) => {
                    'docId': doc.id, 
                    'data': doc.data() as Map<String, dynamic>
                  })
                  .where((item) {
                    final data = item['data'] as Map<String, dynamic>;
                    return !_isSoldStatus(_asText(data['status']));
                  })
                  .toList();

              // LOGIC SẮP XẾP MỚI: Luôn đảm bảo lấy đủ 5 nếu còn hàng
              activeCandidates.sort((a, b) {
                final dataA = a['data'] as Map<String, dynamic>;
                final dataB = b['data'] as Map<String, dynamic>;

                // 1. Ưu tiên theo khoảng giá (Price Bucket)
                bool inBucketA = bucket != null && _asDouble(dataA['price']) >= bucket[0] && _asDouble(dataA['price']) <= bucket[1];
                bool inBucketB = bucket != null && _asDouble(dataB['price']) >= bucket[0] && _asDouble(dataB['price']) <= bucket[1];
                if (inBucketA != inBucketB) return inBucketA ? -1 : 1;

                // 2. Ưu tiên theo Rank
                final rA = _normalizeRankKey(_asText(dataA['rank']));
                final rB = _normalizeRankKey(_asText(dataB['rank']));
                final idxA = rankFallbackKeys.indexOf(rA);
                final idxB = rankFallbackKeys.indexOf(rB);
                if (idxA != idxB) {
                  int scoreA = idxA == -1 ? 99 : idxA;
                  int scoreB = idxB == -1 ? 99 : idxB;
                  return scoreA.compareTo(scoreB);
                }

                // 3. Ưu tiên theo giá trị gần nhất
                final dA = (_asDouble(dataA['price']) - currentPrice).abs();
                final dB = (_asDouble(dataB['price']) - currentPrice).abs();
                return dA.compareTo(dB);
              });

              final suggestions = activeCandidates.take(5).toList();
              if (suggestions.isEmpty) return const Text('Không có đề xuất phù hợp.');

              return ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: suggestions.map((item) {
                      final docId = item['docId'] as String;
                      final data = item['data'] as Map<String, dynamic>;
                      final price = _asDouble(data['price']);
                      final rank = _asText(data['rank']);
                      final heroes = _asText(data['hero_count'], fallback: '0');
                      final skins = _asText(data['skin_count'], fallback: '0');
                      final statusVi = _statusLabelVi(_asText(data['status']));
                      final accId = _asInt(data['id']) ?? 0;

                      return Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: InkWell(
                          onTap: () => _openSuggestedAccount(docId, data, accId),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(_asText(data['image_url']), height: 128, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: const Color(0xFF0F172A), height: 128, child: const Icon(Icons.broken_image, color: Colors.white70))),
                              ),
                              const SizedBox(height: 10),
                              Text('Acc #${accId > 0 ? accId : 'N/A'} - $rank', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Tướng: $heroes | Skin: $skins', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                              Text('${price.toInt()}đ', style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: Text(statusVi, style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600))),
                                  const Text('Xem', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return GestureDetector(
      onTap: () {
        if (_imageUrl.isEmpty) return;
        showDialog(context: context, builder: (ctx) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: Image.network(_imageUrl))));
      },
      child: Container(
        height: isMobile ? 280 : 430,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imageUrl.isEmpty ? const Icon(Icons.broken_image, color: Colors.white) : Image.network(_imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final statusVi = _statusLabelVi(_asText(_account['status']));
    final sold = _isSoldStatus(_asText(_account['status']));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chi tiết tài khoản #$_displayCode', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 15),
        _card([
          _buildInfoRow('Rank hiện tại:', _asText(_account['rank']), isBold: true),
          _buildInfoRow('Số lượng trang phục:', _asText(_account['skin_count'], fallback: '0')),
          _buildInfoRow('Số lượng tướng:', _asText(_account['hero_count'], fallback: '0')),
          _buildInfoRow('Trạng thái:', statusVi),
          const Divider(),
          _buildDescriptionField('Mô tả:', _asText(_account['description'])),
        ]),
        const SizedBox(height: 20),
        _card([_buildPriceRow('Giá tài khoản:', _asDouble(_account['price']))]),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity, height: 55,
          child: ElevatedButton(
            onPressed: sold ? null : _handleBuyFromDetail,
            style: ElevatedButton.styleFrom(backgroundColor: sold ? Colors.grey : const Color(0xFFF97316), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(sold ? 'TÀI KHOẢN ĐÃ BÁN' : 'MUA NGAY TÀI KHOẢN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15)), child: Column(children: children));
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)), Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black))]));
  Widget _buildPriceRow(String label, double price) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)), Text('${price.toInt()}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF97316)))]);
  Widget _buildDescriptionField(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 14, color: Colors.black))]);
}
