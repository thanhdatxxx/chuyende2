
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../widgets/ui_effects.dart';

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

  String _formatMoney(double amount) {
    final digits = amount.toInt().toString();
    final withSeparator = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '$withSeparator đ';
  }

  Future<void> _startPayment(PaymentFlowArgs args) async {
    if (_isPaying) return;
    final auth = context.read<AuthService>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thanh toán!')),
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

      String acc = '-';
      String pass = '-';
      try {
        final creds = await _purchaseService.getTransactionCredentials(
          historyId: result.historyId,
          currentUserName: auth.userName,
        );
        acc = creds['taikhoan'] ?? '-';
        pass = creds['matkhau'] ?? '-';
      } catch (_) {
        // Keep fallback values if credentials are not available.
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            orderId: '#${result.transactionCode}',
            gameNick: '#${args.displayCode}',
            account: acc,
            password: pass,
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      if (error.message == 'INSUFFICIENT_BALANCE') {
        final goTopup = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Số dư không đủ'),
            content: const Text('Tài khoản bạn không đủ tiền. Bạn có muốn đi nạp tiền ngay không?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Nạp ngay')),
            ],
          ),
        );
        if (goTopup == true) {
          Navigator.pushNamed(context, '/bank-atm');
        }
      } else if (error.message == 'ACCOUNT_SOLD') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tài khoản này đã được mua bởi người khác.'), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thanh toán: ${error.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể hoàn tất thanh toán: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! PaymentFlowArgs) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            child: const Text('Thiếu dữ liệu thanh toán. Quay về trang chủ'),
          ),
        ),
      );
    }

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
                _buildTopMenu(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 760),
                        padding: const EdgeInsets.all(24),
                        child: GlassContainer(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'XÁC NHẬN THANH TOÁN',
                                style: TextStyle(
                                  color: Color(0xFFF97316),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _infoRow('Mã nick', '#${args.displayCode}'),
                              _infoRow('Rank', (args.rank ?? '-').isEmpty ? '-' : args.rank!),
                              _infoRow('Tướng/Skin', '${args.heroCount ?? '-'} / ${args.skinCount ?? '-'}'),
                              _infoRow('Số dư hiện tại', _formatMoney(context.watch<AuthService>().balance)),
                              _infoRow('Số tiền thanh toán', _formatMoney(args.price), highlight: true),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isPaying ? null : () => Navigator.pop(context),
                                      child: const Text('Quay lại'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF97316),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _isPaying ? null : () => _startPayment(args),
                                      child: _isPaying
                                          ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
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

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFE5E7EB))),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFF97316) : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              InkWell(onTap: () => Navigator.pushNamed(context, '/'), child: const AnimatedShopName()),
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
                            HoverMenuItem(title: 'Lịch sử giao dịch', icon: Icons.history, onTap: () => Navigator.pushNamed(context, '/history')),
                            const SizedBox(width: 25),
                            const DepositMenuButton(),
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

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.gameNick,
    required this.account,
    required this.password,
  });

  final String orderId;
  final String gameNick;
  final String account;
  final String password;

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
                const SizedBox(height: 80),
                Expanded(
                  child: SingleChildScrollView(
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
                              const Text(
                                'THANH TOÁN THÀNH CÔNG',
                                style: TextStyle(color: Color(0xFFFFF7ED), fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 18),
                              _row(context, 'Mã giao dịch', orderId),
                              _row(context, 'Nick game', gameNick),
                              _row(context, 'Tài khoản', account, copyable: true),
                              _row(context, 'Mật khẩu', password, copyable: true),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF97316),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('QUAY VỀ TRANG CHỦ'),
                                ),
                              ),
                            ],
                          ),
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

  Widget _row(BuildContext context, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFE5E7EB))),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (copyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
                  },
                  child: const Icon(Icons.copy, color: Color(0xFFF97316), size: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
