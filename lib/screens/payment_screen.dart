import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop Khang Payment',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
      ),
      home: const PaymentScreen(),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedNetwork;
  String? selectedAmount;
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final List<String> networks = ['Viettel', 'Mobifone', 'Vinaphone', 'Zing'];
  final List<String> amounts = ['10,000', '20,000', '50,000', '100,000', '200,000', '500,000'];

  @override
  void dispose() {
    _serialController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NẠP TIỀN HỆ THỐNG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner "UY TÍN"
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://img.freepik.com/free-vector/abstract-blue-banner-background_1035-18918.jpg', // Ảnh nền banner xanh
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      child: const Icon(Icons.image, size: 50, color: Colors.blueAccent),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: const Text(
                      'Nạp tiền vào đây nào!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 5,
                        shadows: [
                          Shadow(color: Colors.blueAccent, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thông báo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Lưu ý: Vui lòng nhập đúng số seri và mã thẻ. Nạp sai mệnh giá sẽ mất thẻ!',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // Form nạp thẻ
            const Text('NẠP THẺ CÀO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),

            _buildDropdown('Chọn nhà mạng', networks, selectedNetwork, (val) => setState(() => selectedNetwork = val)),
            const SizedBox(height: 12),
            _buildDropdown('Chọn mệnh giá', amounts, selectedAmount, (val) => setState(() => selectedAmount = val)),
            const SizedBox(height: 12),
            _buildTextField('Số seri', _serialController, TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField('Mã thẻ', _codeController, TextInputType.number),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (selectedNetwork == null || selectedAmount == null || _serialController.text.isEmpty || _codeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang xử lý thẻ...'), backgroundColor: Colors.green),
                  );
                },
                child: const Text('NẠP TIỀN NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),

            // Thông tin chuyển khoản (ATM/MOMO)
            const Text('CHUYỂN KHOẢN ATM / MOMO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            _buildBankInfo('MOMO', '0123456789', 'NGUYEN VAN A'),
            _buildBankInfo('MB BANK', '999999999', 'NGUYEN VAN A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          value: value,
          dropdownColor: Colors.grey[900],
          items: items.map((String item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBankInfo(String name, String stk, String owner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              Text('STK: $stk', style: const TextStyle(fontSize: 15, color: Colors.white)),
              Text('CTK: $owner', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20, color: Colors.blueAccent),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: stk));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép $stk')),
              );
            },
          )
        ],
      ),
    );
  }
}
