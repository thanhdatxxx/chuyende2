import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/ui_effects.dart';

// Màu sắc chủ đạo từ giao diện hình ảnh
const Color primaryColor = Color(0xFF22223b);
const Color secondaryTextColor = Color(0xFF9a9a9a);
const Color linkColor = Color(0xFF5e548e);

// --- TRANG ĐĂNG NHẬP ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _uLogin = TextEditingController();
  final TextEditingController _pLogin = TextEditingController();
  bool _hidePass = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _login() async {
    if (_uLogin.text.isEmpty || _pLogin.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Truy vấn theo collection 'user' và trường 'user_name', 'pass' như trong ảnh
      var userQuery = await _firestore
          .collection('user')
          .where('user_name', isEqualTo: _uLogin.text.trim())
          .where('pass', isEqualTo: _pLogin.text)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final doc = userQuery.docs.first;
        var userData = doc.data();
        String userName = (userData['user_name'] ?? _uLogin.text).toString().trim();
        String fullName = (userData['full_name'] ?? '').toString().trim();
        String userId = (userData['user_id'] ?? doc.id).toString();
        final depositedMoney = _asDouble(userData['deposited_money']);
        final balance = userData.containsKey('balance') ? _asDouble(userData['balance']) : depositedMoney;

        // Cập nhật trạng thái đăng nhập qua Provider
        if (!mounted) return;
        context.read<AuthService>().login(
          userName: userName,
          fullName: fullName,
          userId: userId,
          balance: balance,
          depositedMoney: depositedMoney,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: Colors.green),
        );

        // Quay về trang chủ
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai tài khoản hoặc mật khẩu!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.orange),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
                opacity: 0.82,
                filterQuality: FilterQuality.low,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: GlassContainer(
                  constraints: const BoxConstraints(maxWidth: 500),
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đăng Nhập',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFFF7ED))),
                      const SizedBox(height: 8),
                      const Text('Đăng Nhập Vào Hệ Thống',
                          style: TextStyle(fontSize: 16, color: Color(0xFFFED7AA))),
                      const SizedBox(height: 40),

                      _buildLabel('Tài Khoản'),
                      _buildTextField(_uLogin, 'Nhập Tên Tài Khoản'),

                      const SizedBox(height: 20),

                      _buildLabel('Mật Khẩu'),
                      _buildTextField(_pLogin, 'Nhập Mật Khẩu Của Bạn', isObscure: true),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val!),
                              activeColor: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Ghi Nhớ Tài Khoản', style: TextStyle(color: Color(0xFFFFF7ED), fontSize: 14)),
                          const Spacer(),
                          TextButton(
                              onPressed: () {},
                              child: const Text('Bạn Quên Mật Khẩu?', style: TextStyle(color: Color(0xFFFED7AA), fontSize: 14))
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Đăng Nhập', style: TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      InkWell(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            'Xem không có tài khoản? Ấn vào để về trang chủ',
                            style: TextStyle(
                              color: Color(0xFFFFEDD5),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('BẠN CHƯA CÓ TÀI KHOẢN? ', style: TextStyle(color: Color(0xFFFED7AA), fontSize: 13)),
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: const Text('ĐĂNG KÝ NGAY',
                                style: TextStyle(color: linkColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFFFF7ED),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isObscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure ? _hidePass : false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFFED7AA), fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF97316)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFF97316).withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.6),
        ),
        suffixIcon: isObscure ? IconButton(
          icon: Icon(_hidePass ? Icons.visibility : Icons.visibility_off, color: const Color(0xFFF97316)),
          onPressed: () => setState(() => _hidePass = !_hidePass),
        ) : null,
      ),
      style: const TextStyle(color: Color(0xFFFFF7ED)),
    );
  }
}

// --- TRANG ĐĂNG KÝ ---
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameReg = TextEditingController();
  final TextEditingController _emailReg = TextEditingController();
  final TextEditingController _uReg = TextEditingController();
  final TextEditingController _pReg = TextEditingController();
  final TextEditingController _confirmPReg = TextEditingController();

  bool _hidePass = true;
  bool _hideConfirmPass = true;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _register() async {
    if (_uReg.text.isEmpty || _pReg.text.isEmpty || _fullNameReg.text.isEmpty || _emailReg.text.isEmpty || _confirmPReg.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')));
      return;
    }

    final email = _emailReg.text.trim();
    final password = _pReg.text;
    final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không hợp lệ. Ví dụ: tenban@gmail.com')),
      );
      return;
    }

    if (password.length < 6 || !hasUppercase || !hasLowercase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải từ 6 ký tự và có cả chữ hoa + chữ thường!')),
      );
      return;
    }

    if (_pReg.text != _confirmPReg.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu xác nhận không khớp!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Lưu vào collection 'user' theo đúng cấu trúc ảnh bạn gửi
      await _firestore.collection('user').add({
        'full_name': _fullNameReg.text.trim(),
        'email': _emailReg.text.trim(),
        'user_name': _uReg.text.trim(),
        'pass': _pReg.text,
        'role': 'user',
        'balance': 0,
        'deposited_money': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Cập nhật trạng thái đăng nhập qua Provider
      if (!mounted) return;
      context.read<AuthService>().login(
        userName: _uReg.text.trim(),
        fullName: _fullNameReg.text.trim(),
        userId: _uReg.text.trim(),
        balance: 0,
        depositedMoney: 0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công!'), backgroundColor: Colors.green),
      );

      // Tự động chuyển về trang chủ
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đăng ký: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
                opacity: 0.82,
                filterQuality: FilterQuality.low,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: GlassContainer(
                  constraints: const BoxConstraints(maxWidth: 500),
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đăng Ký',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFFF7ED))),
                      const SizedBox(height: 8),
                      const Text('Tạo Tài Khoản Mới',
                          style: TextStyle(fontSize: 16, color: Color(0xFFFED7AA))),
                      const SizedBox(height: 30),

                      _buildLabel('Họ Tên'),
                      _buildTextField(_fullNameReg, 'Nhập Họ Tên Của Bạn'),

                      const SizedBox(height: 15),

                      _buildLabel('Email'),
                      _buildTextField(_emailReg, 'Nhập Email Của Bạn'),

                      const SizedBox(height: 15),

                      _buildLabel('Tài Khoản'),
                      _buildTextField(_uReg, 'Nhập Tên Tài Khoản'),

                      const SizedBox(height: 15),

                      _buildLabel('Mật Khẩu'),
                      _buildTextField(_pReg, 'Nhập Mật Khẩu', isObscure: true, hideVar: _hidePass, toggle: () => setState(() => _hidePass = !_hidePass)),

                      const SizedBox(height: 15),

                      _buildLabel('Xác Nhận Mật Khẩu'),
                      _buildTextField(_confirmPReg, 'Nhập Lại Mật Khẩu', isObscure: true, hideVar: _hideConfirmPass, toggle: () => setState(() => _hideConfirmPass = !_hideConfirmPass)),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('XÁC NHẬN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('ĐÃ CÓ TÀI KHOẢN? ', style: TextStyle(color: Color(0xFFFED7AA), fontSize: 13)),
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: const Text('ĐĂNG NHẬP',
                                style: TextStyle(color: linkColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFFFF7ED),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isObscure = false, bool? hideVar, VoidCallback? toggle}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure ? (hideVar ?? true) : false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFFED7AA), fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF97316)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFF97316).withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.6),
        ),
        suffixIcon: isObscure ? IconButton(
          icon: Icon((hideVar ?? true) ? Icons.visibility : Icons.visibility_off, color: const Color(0xFFF97316)),
          onPressed: toggle,
        ) : null,
      ),
      style: const TextStyle(color: Color(0xFFFFF7ED)),
    );
  }
}
