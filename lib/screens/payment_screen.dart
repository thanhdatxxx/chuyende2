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

  String _formatMoney(double amount) {
    final digits = amount.toInt().toString();
    final withSeparator = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '$withSeparator đ';
  }

  // # Luồng thanh toán VietQR (Cập nhật cho Apps Script)
  Future<void> _startPayOSPayment(PaymentFlowArgs args) async {
    if (_isPaying) return;
    final auth = context.read<AuthService>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập!')));
      return;
    }

    setState(() => _isPaying = true);

    try {
      final int orderCode = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 1. GỌI BACKEND APPS SCRIPT ĐỂ TẠO LINK
      final response = await _purchaseService.createPayOSLink(
        orderCode: orderCode,
        amount: args.price.toInt(),
        accountCode: args.displayCode.toString(),
      );

      // In log để kiểm tra thực tế server trả về gì (Xem trong Debug Console)
      debugPrint("Full Server Response: $response");

      // 2. KIỂM TRA PHẢN HỒI (Xử lý linh hoạt cho mọi cấu trúc JSON)
      if (response != null) {
        // Tìm checkoutUrl ở cấp cao nhất hoặc trong object 'data'
        dynamic checkoutUrlRaw = response['checkoutUrl'] ?? (response['data'] != null ? response['data']['checkoutUrl'] : null);
        dynamic orderCodeRaw = response['orderCode'] ?? (response['data'] != null ? response['data']['orderCode'] : orderCode);

        if (checkoutUrlRaw != null) {
          final String checkoutUrl = checkoutUrlRaw.toString();
          final String finalOrderCode = orderCodeRaw.toString();

          // 3. TẠO ORDER TRÊN FIREBASE ĐỂ THEO DÕI
          await FirebaseFirestore.instance.collection('orders').add({
            'user_id': auth.userId,
            'account_id': args.accountId, // ID document (ví dụ: 5GrNTB)
            'amount': args.price,
            'status': 'pending',
            'orderCode': orderCode, // Lưu kiểu int để Apps Script tìm kiếm dễ dàng
            'created_at': FieldValue.serverTimestamp(),
          });

          // 4. MỞ TRÌNH DUYỆT THANH TOÁN
          final uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            
            if (mounted) {
              _showWaitingDialog(finalOrderCode, args);
            }
          } else {
            throw 'Không thể mở trình duyệt thanh toán.';
          }
        } else {
          // Trường hợp Server trả về JSON nhưng không có link
          String msg = response['message'] ?? 'Server không trả về checkoutUrl';
          throw msg;
        }
      } else {
        throw 'Không nhận được phản hồi từ Server (Null Response)';
      }
    } catch (e) {
      debugPrint("Payment Page Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _showWaitingDialog(String orderCode, PaymentFlowArgs args) {
    bool isPaymentSuccess = false;
    final auth = context.read<AuthService>();

    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isPaymentSuccess) {
        timer.cancel();
        return;
      }

      try {
        // KIỂM TRA TRONG BẢNG HISTORY THAY VÌ ACCOUNT (Chính xác hơn cho Apps Script)
        final historyQuery = await FirebaseFirestore.instance
            .collection('history')
            .where('account_id', isEqualTo: args.accountId)
            .where('user_id', isEqualTo: auth.userId)
            .limit(1)
            .get();

        if (historyQuery.docs.isNotEmpty) {
          final historyData = historyQuery.docs.first.data();
          
          // Nếu đã có bản ghi history nghĩa là Apps Script đã xử lý xong Webhook
          if (historyData['status'] == 'Thành công') {
            isPaymentSuccess = true;
            timer.cancel();
            if (!mounted) return;
            Navigator.pop(context); // Đóng Dialog chờ
            
            // Chuyển đến màn hình thành công và truyền dữ liệu tk/mk từ history
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentSuccessScreen(
                  orderId: '#$orderCode',
                  gameNick: '#${args.displayCode}',
                  account: historyData['taikhoan'] ?? '-',
                  password: historyData['matkhau'] ?? '-',
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đang chờ thanh toán', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFF97316)),
            SizedBox(height: 20),
            Text('Vui lòng quét mã VietQR.\nHệ thống sẽ tự động chuyển hướng...',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () {
            isPaymentSuccess = true;
            Navigator.pop(ctx);
          }, child: const Text('Đóng')),
        ],
      ),
    );
  }

  // # Luồng thanh toán Ví (Cần đảm bảo Firestore Rules cho phép)
  Future<void> _startPayment(PaymentFlowArgs args) async {
    if (_isPaying) return;
    final auth = context.read<AuthService>();

    if (auth.balance < args.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư không đủ!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isPaying = true);

    try {
      final result = await _purchaseService.purchaseAccount(
        userName: auth.userName,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! PaymentFlowArgs) {
      return const Scaffold(body: Center(child: Text('Lỗi dữ liệu')));
    }

    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            const Text('XÁC NHẬN THANH TOÁN',
                                style: TextStyle(color: Color(0xFFF97316), fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _infoRow('Mã nick', '#${args.displayCode}'),
                            _infoRow('Số tiền thanh toán', _formatMoney(args.price), highlight: true),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('CHỌN PHƯƠNG THỨC', style: TextStyle(color: Colors.white60, fontSize: 13)),
                            ),
                            _methodTile(0, 'Số dư ví', Icons.wallet, subtitle: 'Hiện có: ${_formatMoney(context.watch<AuthService>().balance)}'),
                            _methodTile(1, 'VietQR (Tự động)', Icons.qr_code_scanner, subtitle: 'Cổng PayOS - Xử lý 24/7'),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                                    child: const Text('Quay lại'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
                                    onPressed: _isPaying ? null : () {
                                      if (_selectedMethod == 0) _startPayment(args);
                                      else _startPayOSPayment(args);
                                    },
                                    child: _isPaying 
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                        : const Text('Thanh toán ngay'),
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
        },
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Radio<int>(value: value, groupValue: _selectedMethod, activeColor: const Color(0xFFF97316), onChanged: (v) => setState(() => _selectedMethod = v!)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFE5E7EB))),
          Text(value, style: TextStyle(color: highlight ? const Color(0xFFF97316) : Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
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
