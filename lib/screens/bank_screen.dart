import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/ui_effects.dart';
import '../widgets/home_footer.dart';
import '../widgets/top_menu.dart';

enum DepositMode { none, atm, card }

class BankScreen extends StatefulWidget {
  const BankScreen({super.key, this.initialMode = DepositMode.none});

  final DepositMode initialMode;

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  String? selectedNetwork;
  String? selectedAmount;
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final List<String> networks = ['Viettel', 'Mobifone', 'Vinaphone', 'Zing'];
  final List<String> amounts = ['10,000', '20,000', '50,000', '100,000', '200,000', '500,000'];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _parseAmount(String amountText) {
    final digits = amountText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    // Mặc định luôn là nạp thẻ vì đã bỏ ATM
    _mode = DepositMode.card;
  }

  DepositMode _mode = DepositMode.card;

  @override
  void dispose() {
    _serialController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      _buildCardTemplate(isMobile),
                      const SizedBox(height: 18),
                      _buildCardHistory(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.account_balance_wallet, color: Color(0xFFF97316)),
        ),
        const SizedBox(width: 8),
        const Text(
          'Nạp tiền thẻ cào',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFF7ED)),
        ),
      ],
    );
  }

  Widget _buildCardTemplate(bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Loại Thẻ'),
              _buildDropdown('Chọn loại thẻ', networks, selectedNetwork, (val) => setState(() => selectedNetwork = val)),
              const SizedBox(height: 14),
              _label('Mệnh Giá'),
              _buildDropdown('Chọn mệnh giá', amounts, selectedAmount, (val) => setState(() => selectedAmount = val)),
              const SizedBox(height: 14),
              _label('Số Serial'),
              _buildTextField('Nhập số serial', _serialController),
              const SizedBox(height: 14),
              _label('Mã Thẻ'),
              _buildTextField('Nhập mã thẻ', _codeController),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF97316)),
                ),
                child: const Text(
                  '⚠ Nếu Chọn Sai Mệnh Giá Sẽ Bị Mất Thẻ!!',
                  style: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _onDepositNow,
                  child: const Text('NẠP TIỀN NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LỊCH SỬ NẠP THẺ', style: TextStyle(color: Color(0xFFF97316), fontSize: 40, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _historySearchBar(),
        const SizedBox(height: 10),
        _emptyHistoryBox('Chưa có dữ liệu...'),
      ],
    );
  }

  Widget _historySearchBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.85),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {},
            child: const Icon(Icons.search, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _emptyHistoryBox(String title) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFED7AA))),
            const SizedBox(height: 10),
            const Icon(Icons.person_search, size: 110, color: Color(0xFFB45309)),
          ],
        ),
      ),
    );
  }

  Future<void> _onDepositNow() async {
    if (selectedNetwork == null || selectedAmount == null || _serialController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để nạp tiền!'), backgroundColor: Colors.red),
      );
      return;
    }

    final amount = _parseAmount(selectedAmount!);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mệnh giá không hợp lệ!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final userQuery = await _firestore
          .collection('user')
          .where('user_name', isEqualTo: auth.userName)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy tài khoản người dùng!'), backgroundColor: Colors.red),
        );
        return;
      }

      final userRef = userQuery.docs.first.reference;
      final historyRef = _firestore.collection('history').doc();

      final result = await _firestore.runTransaction<Map<String, double>>((transaction) async {
        final snap = await transaction.get(userRef);
        final data = snap.data() ?? <String, dynamic>{};
        final currentBalance = _asDouble(data['balance']);
        final currentDeposited = _asDouble(data['deposited_money']);
        final updatedBalance = currentBalance + amount;
        final updatedDeposited = currentDeposited + amount;

        transaction.update(userRef, {
          'balance': updatedBalance,
          'deposited_money': updatedDeposited,
          'updated_at': FieldValue.serverTimestamp(),
        });
        transaction.set(historyRef, {
          'type': 'deposit',
          'method': 'card',
          'network': selectedNetwork,
          'amount': amount,
          'serial': _serialController.text.trim(),
          'user_name': auth.userName,
          'balance_after': updatedBalance,
          'created_at': FieldValue.serverTimestamp(),
        });

        return {
          'balance': updatedBalance,
          'deposited_money': updatedDeposited,
        };
      });

      auth.updateMoney(
        balance: result['balance'] ?? auth.balance,
        depositedMoney: result['deposited_money'] ?? auth.depositedMoney,
      );

      _serialController.clear();
      _codeController.clear();
      setState(() {
        selectedAmount = null;
        selectedNetwork = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nạp tiền thành công: +$amount đ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể nạp tiền: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Color(0xFFFED7AA), fontWeight: FontWeight.w700, fontSize: 18));

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          value: value,
          dropdownColor: Colors.white,
          items: items.map((String item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFF7C2D12), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD39B57)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF97316)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF97316)),
        ),
      ),
    );
  }
}
