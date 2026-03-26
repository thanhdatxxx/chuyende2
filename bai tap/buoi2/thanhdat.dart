import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const InterestCalculatorApp());
}

class InterestCalculatorApp extends StatelessWidget {
  const InterestCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.grey),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  String _result = "";

  void _calculateYears() {
    double? rate = double.tryParse(_rateController.text);
    if (rate != null && rate > 0) {
      double years = log(2) / log(1 + (rate / 100));
      setState(() {
        _result = "${years.toStringAsFixed(2)} năm";
      });
    } else {
      setState(() {
        _result = "Lỗi!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        leading: const Icon(Icons.menu, color: Colors.black),
        title: const Row(
          children: [
            Text('Máy tính lãi suất', style: TextStyle(fontSize: 18, color: Colors.black)),
            Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
        actions: const [Icon(Icons.more_vert, color: Colors.black), SizedBox(width: 10)],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildInputField("Số tiền", _amountController),
            const SizedBox(height: 20),
            _buildInputField("Lãi hàng năm", _rateController),
            const SizedBox(height: 30),
            Row(
              children: [
                const Expanded(
                  child: Text("Số năm để tiền tăng gấp đôi", style: TextStyle(fontSize: 14)),
                ),
                Text(_result, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: _calculateYears,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text("Tính toán"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.all(10),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
        ),
      ],
    );
  }
}