import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../widgets/ui_effects.dart';

class HistoryTransactionDetailScreen extends StatefulWidget {
  const HistoryTransactionDetailScreen({super.key});

  @override
  State<HistoryTransactionDetailScreen> createState() => _HistoryTransactionDetailScreenState();
}

class _HistoryTransactionDetailScreenState extends State<HistoryTransactionDetailScreen> {
  final PurchaseService _purchaseService = PurchaseService();

  Map<String, dynamic>? _payload;
  int? _requestedAccountCode;
  bool _loading = true;
  String? _error;
  bool _showPassword = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading || _payload != null || _error != null) return;
    _loadData();
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final argMap = args is Map ? Map<String, dynamic>.from(args) : const <String, dynamic>{};
    _requestedAccountCode = _asInt(argMap['accountCode']);
    final historyId = (argMap['historyId'] ?? '').toString();

    if (historyId.isEmpty) {
      setState(() {
        _error = 'Thiếu mã giao dịch để xem chi tiết.';
        _loading = false;
      });
      return;
    }

    try {
      final auth = context.read<AuthService>();
      final data = await _purchaseService.getPurchasedAccountDetail(
        historyId: historyId,
        currentUserName: auth.userName,
      );
      if (!mounted) return;
      setState(() {
        _payload = data;
        _loading = false;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      final message = switch (error.message) {
        'FORBIDDEN' => 'Bạn không có quyền xem giao dịch này.',
        'MISSING_CREDENTIALS' => 'Tài khoản chưa có đủ thông tin đăng nhập để hiển thị.',
        'TRANSACTION_NOT_FOUND' => 'Không tìm thấy giao dịch.',
        'ACCOUNT_NOT_FOUND' => 'Không tìm thấy tài khoản của giao dịch.',
        _ => 'Không thể tải chi tiết giao dịch: ${error.message}',
      };
      setState(() {
        _error = message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải chi tiết giao dịch. Vui lòng thử lại.';
        _loading = false;
      });
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

  String _formatMoney(double amount) {
    final digits = amount.toInt().toString();
    final withSeparator = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '$withSeparator đ';
  }

  int _resolveDisplayCode(Map<String, dynamic> payload) {
    return _requestedAccountCode ?? _asInt(payload['account_code']) ?? 0;
  }

  String get _imageUrl => _asText(_payload?['image_url'], fallback: '');

  Future<void> _copyToClipboard(String value, String label) async {
    if (value.trim().isEmpty || value == '-') return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Da sao chep $label')),
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
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 640),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Color(0xFFFFF7ED), fontSize: 16)),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final payload = _payload ?? const <String, dynamic>{};
    final displayCode = _resolveDisplayCode(payload);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSection = _buildImageSection();
        final infoSection = _buildInfoSection(displayCode, payload);
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: imageSection),
              const SizedBox(width: 30),
              Expanded(flex: 2, child: infoSection),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              imageSection,
              const SizedBox(height: 30),
              infoSection,
            ],
          ),
        );
      },
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

  Widget _buildInfoSection(int displayCode, Map<String, dynamic> payload) {
    final rank = _asText(payload['rank']);
    final skins = _asText(payload['skin_count'], fallback: '0');
    final heroes = _asText(payload['hero_count'], fallback: '0');
    final status = _asText(payload['status'], fallback: 'Đã bán');
    final price = _asDouble(payload['price']);
    final username = _asText(payload['taikhoan']);
    final password = _asText(payload['matkhau']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết giao dịch - Tài khoản #$displayCode',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
              _buildPriceRow('Giá đã thanh toán:', price, isBold: true),
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
              _buildCredentialRow(
                label: 'Tài khoản:',
                value: username,
                isBold: true,
                onCopy: () => _copyToClipboard(username, 'tai khoan'),
              ),
              _buildCredentialRow(
                label: 'Mật khẩu:',
                value: _showPassword ? password : '********',
                onCopy: () => _copyToClipboard(password, 'mat khau'),
                onToggleVisibility: () => setState(() => _showPassword = !_showPassword),
                isPasswordVisible: _showPassword,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          ),
          if (trailing != null) trailing,
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool isBold = false,
    VoidCallback? onToggleVisibility,
    bool isPasswordVisible = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
            ),
          ),
          if (onToggleVisibility != null)
            IconButton(
              tooltip: isPasswordVisible ? 'An mat khau' : 'Hien mat khau',
              onPressed: onToggleVisibility,
              icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility),
            ),
          IconButton(
            tooltip: 'Sao chep',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
          ),
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
          _formatMoney(price),
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFFF97316),
          ),
        ),
      ],
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
}

