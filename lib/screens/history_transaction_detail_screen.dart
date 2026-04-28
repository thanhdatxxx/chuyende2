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
    
    // Đồng bộ: Ưu tiên lấy displayCode được truyền sang, nếu không có thì lấy từ id hoặc accountCode
    _requestedAccountCode = _asInt(argMap['displayCode']) ?? _asInt(argMap['id']) ?? _asInt(argMap['accountCode']);
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải chi tiết giao dịch: $e';
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
    // Ưu tiên id thật (260001) từ Firestore
    return _requestedAccountCode ?? _asInt(payload['id']) ?? _asInt(payload['account_code']) ?? 0;
  }

  String get _imageUrl => _asText(_payload?['image_url'], fallback: '');

  Future<void> _copyToClipboard(String value, String label) async {
    if (value.trim().isEmpty || value == '-') return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label')),
    );
  }

  void _openFullImage() {
    if (_imageUrl.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              InteractiveViewer(
                maxScale: 10,
                minScale: 0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
            ],
          ),
        ),
      );
    }

    final payload = _payload ?? {};
    final displayCode = _resolveDisplayCode(payload);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 900;
        return SingleChildScrollView(
          child: isWide 
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _buildImageSection()),
                const SizedBox(width: 30),
                Expanded(flex: 2, child: _buildInfoSection(displayCode, payload)),
              ])
            : Column(children: [
                _buildImageSection(),
                const SizedBox(height: 30),
                _buildInfoSection(displayCode, payload),
              ]),
        );
      },
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _openFullImage,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imageUrl.isEmpty
                ? const Icon(Icons.broken_image, color: Colors.white, size: 50)
                : Image.network(_imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(int displayCode, Map<String, dynamic> payload) {
    final price = _asDouble(payload['price']);
    final username = _asText(payload['taikhoan']);
    final password = _asText(payload['matkhau']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tài khoản #$displayCode', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        _card([
          _infoRow('Rank:', _asText(payload['rank']), isBold: true),
          _infoRow('Trang phục:', _asText(payload['skin_count'], fallback: '0')),
          _infoRow('Tướng:', _asText(payload['hero_count'], fallback: '0')),
        ]),
        const SizedBox(height: 20),
        _card([
          _priceRow('Giá niêm yết:', price),
          _priceRow('Đã thanh toán:', _asDouble(payload['amount']), isBold: true),
        ]),
        const SizedBox(height: 20),
        _card([
          _credentialRow('Tài khoản:', username, () => _copyToClipboard(username, 'tài khoản')),
          _credentialRow(
            'Mật khẩu:', 
            _showPassword ? password : '********', 
            () => _copyToClipboard(password, 'mật khẩu'),
            onToggle: () => setState(() => _showPassword = !_showPassword),
            isVisible: _showPassword,
          ),
        ]),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15)),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
      ]),
    );
  }

  Widget _priceRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text(_formatMoney(amount), style: TextStyle(color: Colors.orange, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 18)),
      ]),
    );
  }

  Widget _credentialRow(String label, String value, VoidCallback onCopy, {VoidCallback? onToggle, bool isVisible = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (onToggle != null) IconButton(icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: onToggle),
        IconButton(icon: const Icon(Icons.copy, size: 20, color: Colors.orange), onPressed: onCopy),
      ]),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(onTap: () => Navigator.pushNamed(context, '/'), child: const Text("SHOP LIÊN QUÂN", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20))),
          IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/')),
        ]),
      ),
    );
  }
}
