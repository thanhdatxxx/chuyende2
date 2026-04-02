import 'package:flutter/material.dart';
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
    return normalized.contains('đã bán') || normalized.contains('da ban');
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/anh-lien-quan-4k-thu-nguyen-ve-than-66.jpg'),
                fit: BoxFit.cover,
                opacity: 0.78,
                filterQuality: FilterQuality.low,
              ),
            ),
            child: Column(
              children: [
                _buildTopMenu(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 900) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: _buildImageSection()),
                                  const SizedBox(width: 30),
                                  Expanded(flex: 2, child: _buildInfoSection()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildImageSection(),
                                const SizedBox(height: 30),
                                _buildInfoSection(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 14,
            right: 14,
            child: SafeArea(child: FloatingMusicButton()),
          ),
        ],
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
    final price = _asDouble(_account['price']);
    final sold = _isSoldStatus(status);

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
              _buildInfoRow('Trạng thái:', status),
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
}
