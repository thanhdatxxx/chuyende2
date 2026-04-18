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
  Map<String, dynamic> _bankConfig = const {
    'bank_name': 'BIDV',
    'account_name': 'Nguyen Tan Dung',
    'account_number': '2601647122',
    'transfer_suffix': 'chuyenkhoan',
  };

  DepositMode _mode = DepositMode.none;

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
    _mode = widget.initialMode;
    _ensureBankSeedAndLoad();
  }

  Future<void> _ensureBankSeedAndLoad() async {
    final docRef = _firestore.collection('bank').doc('default');
    final defaultData = {
      'bank_name': 'BIDV',
      'account_name': 'Nguyen Tan Dung',
      'account_number': '2601647122',
      'transfer_suffix': 'chuyenkhoan',
      'updated_at': FieldValue.serverTimestamp(),
    };

    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set(defaultData);
      if (!mounted) return;
      setState(() => _bankConfig = defaultData);
      return;
    }

    final data = snap.data() ?? {};
    if (!mounted) return;
    setState(() {
      _bankConfig = {
        ...defaultData,
        ...data,
      };
    });
  }

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
                      if (_mode != DepositMode.atm) _buildCardTemplate(isMobile),
                      if (_mode == DepositMode.none) const SizedBox(height: 14),
                      if (_mode != DepositMode.card) _buildAtmTemplate(isMobile),
                      const SizedBox(height: 18),
                      if (_mode == DepositMode.card) _buildCardHistory(),
                      if (_mode == DepositMode.atm) _buildAtmHistory(),
                      if (_mode == DepositMode.none)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Text(
                            'Nhấn "NẠP TIỀN NGAY" rồi chọn "NẠP TIỀN ATM" hoặc "NẠP TIỀN THẺ" để xem mẫu tương ứng.',
                            style: TextStyle(color: Color(0xFFFED7AA), fontWeight: FontWeight.w600),
                          ),
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
          'Nạp tiền',
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
              const SizedBox(height: 12),
              _buildModeSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtmTemplate(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: isMobile
          ? Column(
        children: [_buildManualCard(), const SizedBox(height: 10), _buildQrCard()],
      )
          : Row(
        children: [
          Expanded(child: _buildManualCard()),
          const SizedBox(width: 10),
          Expanded(child: _buildQrCard()),
        ],
      ),
    );
  }

  Widget _buildManualCard() {
    final auth = context.watch<AuthService>();
    final bankName = (_bankConfig['bank_name'] ?? 'BIDV').toString();
    final accountName = (_bankConfig['account_name'] ?? 'Nguyen Tan Dung').toString();
    final accountNumber = (_bankConfig['account_number'] ?? '2601647122').toString();
    final userName = auth.userName.trim();
    final transferContent = '${userName.isEmpty ? 'guest' : userName}chuyenkhoan';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cách 1: Chuyển thủ công (Ngân hàng, MoMo, ZaloPay)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFF7ED))),
          const SizedBox(height: 8),
          const Text('Mở app ngân hàng, MoMo hoặc ZaloPay rồi chuyển khoản đúng nội dung bên dưới. Tiền cộng tự động.', style: TextStyle(color: Color(0xFFFFF7ED))),
          const SizedBox(height: 10),
          _copyBox('Ngân hàng', bankName, canCopy: false),
          _copyBox('Chủ tài khoản', accountName, canCopy: false),
          _copyBox('Số tài khoản', accountNumber),
          _copyBox('Nội dung chuyển khoản (Quan trọng)', transferContent, highlighted: true),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lưu ý: vui lòng sao chép đúng nội dung chuyển khoản $transferContent để hệ thống tự động cộng tiền cho bạn',
              style: const TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Cách 2: Dùng app Ngân hàng, MoMo, ZaloPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFF7ED))),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dùng app ngân hàng, MoMo hoặc ZaloPay và quét mã QR để chuyển khoản. Hệ thống tự động cộng tiền.',
            style: TextStyle(color: Color(0xFFFFF7ED)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF97316)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/anhthanhtoan.jpg', fit: BoxFit.cover, filterQuality: FilterQuality.low),
            ),
          ),
        ],
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
        _emptyHistoryBox('No data'),
      ],
    );
  }

  Widget _buildAtmHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LỊCH SỬ NẠP TIỀN', style: TextStyle(color: Color(0xFFF97316), fontSize: 40, fontWeight: FontWeight.bold)),
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

  Widget _buildModeSwitch() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _switchBtn('NẠP TIỀN ATM', DepositMode.atm),
        _switchBtn('NẠP TIỀN THẺ', DepositMode.card),
      ],
    );
  }

  Widget _switchBtn(String title, DepositMode mode) {
    final isSelected = _mode == mode;
    return ElevatedButton(
      onPressed: () => setState(() => _mode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFF97316) : const Color(0xFFF4B35A),
        foregroundColor: const Color(0xFF5B2A00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _copyBox(String label, String value, {bool canCopy = true, bool highlighted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF97316).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF7C2D12), fontSize: 16)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Color(0xFF5B2A00), fontWeight: FontWeight.bold, fontSize: 24)),
              ],
            ),
          ),
          if (canCopy)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã sao chép $value')),
                );
              },
              icon: const Icon(Icons.copy, color: Color(0xFF5B2A00)),
              label: const Text('Sao chép', style: TextStyle(color: Color(0xFF5B2A00), fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
