import 'package:flutter/material.dart';
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
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
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
                        const SizedBox(height: 40),
                      ],
                    );
                  },
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
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildInfoRow('Rank hiện tại:', rank, isBold: true),
              _buildInfoRow('Số lượng trang phục:', skins),
              _buildInfoRow('Số lượng tướng:', heroes),
              _buildInfoRow('Trạng thái:', statusVi),
              const Divider(),
              _buildDescriptionField('Mô tả:', description),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildPriceRow('Giá tài khoản:', price),
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
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        Text(
          '${price.toInt()}đ',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }
}
