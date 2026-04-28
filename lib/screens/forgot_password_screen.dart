import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/ui_effects.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  int _step = 1;
  String? _generatedOtp;
  String? _userDocId;
  bool _isLoading = false;
  bool _hidePass = true;

  // Cấu hình EmailJS CHÍNH THỨC
  final String serviceId = 'service_j4tt4o6';
  final String templateId = 'template_fyqz9uf';
  final String publicKey = 'M-YbliMxHWWDZn1SI';

  // 1. Gửi OTP
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMsg('Vui lòng nhập Email!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Kiểm tra email trong Firestore
      var userQuery = await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        _showMsg('Email này không tồn tại trên hệ thống!');
        return;
      }
      _userDocId = userQuery.docs.first.id;

      // Tạo mã OTP 6 số ngẫu nhiên
      _generatedOtp = (Random().nextInt(900000) + 100000).toString();

      // Gọi API EmailJS
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': email,
            'otp_code': _generatedOtp,
          }
        }),
      );

      if (response.statusCode == 200) {
        _showMsg('Mã OTP đã được gửi đến Email: $email', isSuccess: true);
        setState(() => _step = 2);
      } else {
        print("Lỗi EmailJS: ${response.body}");
        _showMsg('Lỗi gửi mail (${response.statusCode}). Vui lòng thử lại sau!');
      }
    } catch (e) {
      _showMsg('Lỗi hệ thống: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Xác nhận OTP
  void _verifyOtp() {
    if (_otpController.text.trim() == _generatedOtp) {
      setState(() => _step = 3);
    } else {
      _showMsg('Mã OTP không chính xác!');
    }
  }

  // 3. Cập nhật mật khẩu mới
  Future<void> _resetPassword() async {
    if (_newPassController.text.length < 6) {
      _showMsg('Mật khẩu mới phải từ 6 ký tự!');
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      _showMsg('Mật khẩu xác nhận không khớp!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(_userDocId)
          .update({
            'pass': _newPassController.text,
            'last_password_reset': FieldValue.serverTimestamp(),
          });

      _showMsg('Mật khẩu đã được cập nhật thành công!', isSuccess: true);
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
      }
    } catch (e) {
      _showMsg('Lỗi cập nhật mật khẩu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/anh-lien-quan-4k-thu-nguyen-ve-than-66.jpg'),
                fit: BoxFit.cover, 
                opacity: 0.8
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: GlassContainer(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  borderRadius: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _step == 1 ? 'Quên Mật Khẩu' : (_step == 2 ? 'Xác Thực OTP' : 'Mật Khẩu Mới'),
                        style: const TextStyle(fontSize: 28, color: Color(0xFFFFF7ED), fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _step == 1 ? 'Nhập email để nhận mã khôi phục' : (_step == 2 ? 'Chúng tôi đã gửi mã 6 số tới Email của bạn' : 'Vui lòng thiết lập mật khẩu mới'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFED7AA), fontSize: 15)
                      ),
                      const SizedBox(height: 35),
                      
                      if (_step == 1) ...[
                        _buildLabel('Email đăng ký'),
                        _buildTextField(_emailController, 'example@gmail.com', icon: Icons.email_outlined),
                        const SizedBox(height: 30),
                        _buildButton('GỬI MÃ XÁC NHẬN', _sendOtp),
                      ] else if (_step == 2) ...[
                        _buildLabel('Mã OTP (6 số)'),
                        _buildTextField(_otpController, 'xxxxxx', icon: Icons.lock_clock_outlined, isNumeric: true),
                        const SizedBox(height: 30),
                        _buildButton('XÁC THỰC', _verifyOtp),
                      ] else ...[
                        _buildLabel('Mật Khẩu Mới'),
                        _buildTextField(_newPassController, 'Ít nhất 6 ký tự', isPass: true, icon: Icons.lock_outline),
                        const SizedBox(height: 15),
                        _buildLabel('Xác Nhận Mật Khẩu'),
                        _buildTextField(_confirmPassController, 'Nhập lại mật khẩu', isPass: true, icon: Icons.verified_user_outlined),
                        const SizedBox(height: 30),
                        _buildButton('ĐỔI MẬT KHẨU', _resetPassword),
                      ],
                      
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại Đăng nhập', 
                          style: TextStyle(color: Color(0xFFFED7AA), fontSize: 15, decoration: TextDecoration.underline)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFFFF7ED))),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isPass = false, IconData? icon, bool isNumeric = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass ? _hidePass : false,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Color(0xFFFFF7ED)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFFED7AA), fontSize: 14),
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFF97316), size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF97316))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFF97316).withOpacity(0.4))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5)),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_hidePass ? Icons.visibility : Icons.visibility_off, color: const Color(0xFFF97316), size: 20),
          onPressed: () => setState(() => _hidePass = !_hidePass),
        ) : null,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback press) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF97316), // Đổi sang màu Cam cho đồng bộ nút chính
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : press,
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }
}
