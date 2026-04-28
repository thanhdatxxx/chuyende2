import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../widgets/ui_effects.dart';
import '../widgets/home_footer.dart';
import '../widgets/top_menu.dart';

// # Lớp chứa các tham số truyền vào luồng thanh toán
class PaymentFlowArgs {
  const PaymentFlowArgs({
    required this.accountId,    
    required this.displayCode,     
    required this.price,
    this.rank,
    this.heroCount,
    this.skinCount,
  });

  final String accountId;    
  final int displayCode;     
  final double price;
  final String? rank;
  final String? heroCount;
  final String? skinCount;
}

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isPaying = false;
  int _selectedMethod = 0; // 0: Ví, 1: VietQR

  @override
  void initState() {
    super.initState();
    _checkUrlParameters();
  }

  // Kiểm tra tham số URL ngay khi vào màn hình
  void _checkUrlParameters() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final params = Uri.base.queryParameters;
      if (params['status'] == 'CANCELLED') {
        final String? oCode = params['orderCode'];
        if (oCode != null) {
          // Cập nhật Firestore để Tab cũ tự đóng Dialog
          _purchaseService.updateOrderCancel(int.parse(oCode));
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã hủy thanh toán đơn hàng.'))
          );
          
          // KHÔNG gọi Navigator.pop ở đây để giữ màn hình thông báo Hủy
        }
      }
    });
  }

  String _formatMoney(double amount) {
    final digits = amount.toInt().toString();
    final withSeparator = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '$withSeparator đ';
  }

  // Hiển thị UI kết quả trả về từ PayOS (Màn hình có X đỏ hoặc Check xanh)
  Widget? _buildPayOSResultUI() {
    final params = Uri.base.queryParameters;
    if (!params.containsKey('status')) return null;

    final status = params['status'];
    final orderCode = params['orderCode'] ?? "N/A";
    final bool isSuccess = status == "PAID";
    final bool isCancelled = status == "CANCELLED";

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : (isCancelled ? Icons.cancel : Icons.info_outline),
                color: isSuccess ? Colors.green : (isCancelled ? Colors.orange : Colors.blue),
                size: 70,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'THANH TOÁN THÀNH CÔNG!' : (isCancelled ? 'GIAO DỊCH ĐÃ HỦY' : 'KẾT QUẢ GIAO DỊCH'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess 
                    ? 'Đơn hàng #$orderCode đã thanh toán thành công. Bạn có thể đóng tab này và quay lại tab cũ để nhận tài khoản.'
                    : 'Yêu cầu thanh toán cho đơn hàng #$orderCode đã bị hủy theo yêu cầu của bạn.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                  child: const Text('VỀ TRANG CHỦ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startPayOSPayment(PaymentFlowArgs args) async {
    if (_isPaying) return;
    final auth = context.read<AuthService>();
    setState(() => _isPaying = true);

    try {
      final int orderCode = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _purchaseService.createPendingOrder(
        orderCode: orderCode,
        userId: auth.userId,
        accountDocId: args.accountId,
        id: args.displayCode.toString(),
        price: args.price,
      );

      final response = await _purchaseService.createPayOSLink(
        orderCode: orderCode,
        amount: args.price.toInt(),
        accountIdReal: args.displayCode.toString(),
      );

      if (response != null) {
        dynamic url = response['checkoutUrl'] ?? (response['data'] != null ? response['data']['checkoutUrl'] : null);
        if (url != null) {
          await launchUrl(Uri.parse(url.toString()), mode: LaunchMode.externalApplication);
          if (mounted) _showWaitingDialog(orderCode.toString(), args);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _showWaitingDialog(String orderCode, PaymentFlowArgs args) {
    StreamSubscription? successSub;
    StreamSubscription? statusSub;

    // 1. Lắng nghe thành công (từ history)
    successSub = _purchaseService.listenToPurchaseHistory(int.parse(orderCode)).listen((doc) {
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          successSub?.cancel();
          statusSub?.cancel();
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                orderId: '#$orderCode',
                gameNick: '#${args.displayCode}',
                account: data['taikhoan'] ?? '-',
                password: data['matkhau'] ?? '-',
              ),
            ),
          );
        }
      }
    });

    // 2. Lắng nghe hủy đơn (từ orders) - Để đóng dialog ở Tab cũ khi Tab mới nhấn Hủy
    statusSub = _purchaseService.listenToPaymentStatus(int.parse(orderCode)).listen((doc) {
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'cancelled') {
          if (mounted) {
            successSub?.cancel();
            statusSub?.cancel();
            Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog "Đang chờ"
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Giao dịch đã bị hủy.'))
            );
          }
        }
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đang chờ thanh toán', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Color(0xFFF97316)),
              const SizedBox(height: 24),
              const Text('Vui lòng hoàn tất thanh toán trên ứng dụng Ngân hàng.\nTrang sẽ tự động cập nhật ngay khi nhận được tiền...',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Text('Đơn hàng: #$orderCode', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                successSub?.cancel();
                statusSub?.cancel();
                Navigator.pop(ctx);
              },
              child: const Text('Hủy kiểm tra', style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    ).then((_) {
      successSub?.cancel();
      statusSub?.cancel();
    });
  }

  Future<void> _startPayment(PaymentFlowArgs args) async {
    if (_isPaying) return;
    final auth = context.read<AuthService>();
    if (auth.balance < args.price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư ví không đủ!')));
      return;
    }
    setState(() => _isPaying = true);
    try {
      final result = await _purchaseService.purchaseAccount(
        userName: auth.userName,
        userId: auth.userId,
        accountId: args.accountId,
        accountCode: args.displayCode,
        price: args.price,
      );
      auth.updateMoney(balance: result.newBalance);
      final creds = await _purchaseService.getTransactionCredentials(
        historyId: result.historyId,
        currentUserName: auth.userName,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            orderId: '#${result.transactionCode}',
            gameNick: '#${args.displayCode}',
            account: creds['taikhoan'] ?? '-',
            password: creds['matkhau'] ?? '-',
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ưu tiên hiển thị UI kết quả nếu URL có tham số status
    final payOSResult = _buildPayOSResultUI();
    if (payOSResult != null) {
      return EffectPageScaffold(
        topMenu: const TopMenu(),
        body: Column(children: [Expanded(child: payOSResult), const HomeFooter()]),
      );
    }

    // 2. Nếu không có status, hiển thị form xác nhận thanh toán bình thường
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! PaymentFlowArgs) {
      return const Scaffold(body: Center(child: Text('Lỗi: Không tìm thấy thông tin tài khoản.')));
    }

    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 760),
                padding: const EdgeInsets.all(24),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(color: Color(0xFFF97316), fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _infoRow('Mã nick', '#${args.displayCode}'),
                      _infoRow('Số tiền thanh toán', _formatMoney(args.price), highlight: true),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('CHỌN PHƯƠNG THỨC', style: TextStyle(color: Colors.white60, fontSize: 13))),
                      _methodTile(0, 'Số dư ví', Icons.wallet, subtitle: 'Hiện có: ${_formatMoney(context.watch<AuthService>().balance)}'),
                      _methodTile(1, 'VietQR (Tự động)', Icons.qr_code_scanner, subtitle: 'Cổng PayOS - Xử lý 24/7'),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại'))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isPaying ? null : () => _selectedMethod == 0 ? _startPayment(args) : _startPayOSPayment(args),
                              child: _isPaying ? const CircularProgressIndicator() : const Text('Thanh toán ngay'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(int value, String title, IconData icon, {String? subtitle}) {
    bool isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFF97316) : Colors.white10),
          color: isSelected ? const Color(0xFFF97316).withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFF97316) : Colors.white54),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])),
            Radio<int>(value: value, groupValue: _selectedMethod, activeColor: const Color(0xFFF97316), onChanged: (v) => setState(() => _selectedMethod = v!)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Color(0xFFE5E7EB))), Text(value, style: TextStyle(color: highlight ? const Color(0xFFF97316) : Colors.white, fontWeight: FontWeight.w700))]));
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.orderId, required this.gameNick, required this.account, required this.password});
  final String orderId, gameNick, account, password;

  @override
  Widget build(BuildContext context) {
    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: GlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF4ADE80), size: 90),
                        const SizedBox(height: 16),
                        const Text('THANH TOÁN THÀNH CÔNG', style: TextStyle(color: Color(0xFFFFF7ED), fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 18),
                        _row(context, 'Mã giao dịch', orderId),
                        _row(context, 'Nick game', gameNick),
                        _row(context, 'Tài khoản', account, copyable: true),
                        _row(context, 'Mật khẩu', password, copyable: true),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                            child: const Text('VỀ TRANG CHỦ'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.white60))),
          Expanded(flex: 4, child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Color(0xFFF97316)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép vào bộ nhớ tạm')));
              },
            ),
        ],
      ),
    );
  }
}
