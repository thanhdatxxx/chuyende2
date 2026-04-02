import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/ui_effects.dart';

class DetailUserPage extends StatefulWidget {
  const DetailUserPage({super.key});

  @override
  State<DetailUserPage> createState() => _DetailUserPageState();
}

class _DetailUserPageState extends State<DetailUserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _activityPage = 1;
  static const int _activityPerPage = 8;
  
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  
  String _formatMoney(double amount) {
    final digits = amount.toInt().toString();
    final withSeparator = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '$withSeparator đ';
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final dt = timestamp.toDate();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$hh:$mm - $dd/$mo/${dt.year}';
  }

  String _activityTitle(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().trim().toLowerCase();
    if (type == 'purchase') {
      final code = (data['account_code'] ?? '-').toString();
      final amount = _asDouble(data['amount']);
      return 'Mua tài khoản #$code (${_formatMoney(amount)})';
    }
    if (type == 'deposit') {
      final amount = _asDouble(data['amount']);
      return 'Nạp tiền vào tài khoản (${_formatMoney(amount)})';
    }
    if (type == 'account_update') {
      final action = (data['action'] ?? '').toString().trim().toLowerCase();
      if (action == 'change_password') return 'Đổi mật khẩu tài khoản';
      return (data['description'] ?? 'Cập nhật thông tin tài khoản').toString();
    }
    final description = (data['description'] ?? '').toString();
    return description.isEmpty ? 'Cập nhật tài khoản' : description;
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
            child: Column(
              children: [
                _buildTopMenu(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 900) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 15),
                                          child: _buildAccountInfo(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 15),
                                          child: _buildChangePassword(),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildAccountInfo(),
                                      const SizedBox(height: 20),
                                      _buildChangePassword(),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 30),
                            _buildActivityLog(),
                            const SizedBox(height: 50),
                          ],
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

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/'),
                child: const AnimatedShopName(),
              ),
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
                        _buildMenuItem('Đăng ký', null, () => Navigator.pushNamed(context, '/register')),
                        const SizedBox(width: 25),
                        _buildMenuItem('Đăng nhập', null, () => Navigator.pushNamed(context, '/login')),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        _buildMenuItem('Trang chủ', Icons.home, () => Navigator.pushNamed(context, '/')),
                        const SizedBox(width: 20),
                        _buildMenuItem('Lịch sử giao dịch', Icons.history, () {
                          Navigator.pushNamed(context, '/history');
                        }),
                        const SizedBox(width: 20),
                        const DepositMenuButton(),
                        const SizedBox(width: 30),
                        Row(
                          children: [
                            Text(
                              authService.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFF7ED),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                              ),
                              child: PopupMenuButton(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                position: PopupMenuPosition.under,
                                offset: const Offset(12, 10),
                                constraints: const BoxConstraints(minWidth: 190),
                                color: Colors.white.withValues(alpha: 0.16),
                                surfaceTintColor: Colors.transparent,
                                shadowColor: Colors.black.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                                ),
                                icon: const Icon(Icons.account_circle, color: Color(0xFFF97316), size: 30),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Text('Thông tin cá nhân', style: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600)),
                                    onTap: () {
                                      Navigator.pushNamed(context, '/user-detail');
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600)),
                                    onTap: () {
                                      context.read<AuthService>().logout();
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/',
                                        (route) => false,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đăng xuất thành công!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
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

  Widget _buildMenuItem(String title, IconData? icon, VoidCallback onTap) {
    return HoverMenuItem(title: title, icon: icon, onTap: onTap);
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THÔNG TIN TÀI KHOẢN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoField('Tên Đăng Nhập', authService.userName),
              const SizedBox(height: 15),
              _buildInfoField('Tên đầy đủ', authService.fullName.isEmpty ? '-' : authService.fullName),
              const SizedBox(height: 15),
              _buildInfoField('Ngày Đăng Ký', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              const SizedBox(height: 15),
              _buildInfoField('Số Tiền Hiện Có', _formatMoney(authService.balance)),
              const SizedBox(height: 15),
              _buildInfoField('Tổng Tiền Đã Nạp', _formatMoney(authService.depositedMoney)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePassword() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THAY ĐỔI MẬT KHẨU',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildPasswordField('Mật Khẩu Cũ', _oldPasswordController, _showOldPassword, (value) {
            setState(() => _showOldPassword = value);
          }),
          const SizedBox(height: 15),
          _buildPasswordField('Mật Khẩu Mới', _newPasswordController, _showNewPassword, (value) {
            setState(() => _showNewPassword = value);
          }),
          const SizedBox(height: 15),
          _buildPasswordField('Xác Nhận Mật Khẩu', _confirmPasswordController, _showConfirmPassword, (value) {
            setState(() => _showConfirmPassword = value);
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Đổi Mật Khẩu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool showPassword,
    Function(bool) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: Color(0xFFFED7AA)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.orange.shade400,
              ),
              onPressed: () => onToggle(!showPassword),
            ),
          ),
          style: const TextStyle(color: Color(0xFFFFF7ED)),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại để thực hiện thao tác này!'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Không tìm thấy người dùng!'), backgroundColor: Colors.red),
        );
        return;
      }

      final userDoc = userQuery.docs.first;
      final currentPassword = (userDoc.data()['pass'] ?? '').toString();
      if (_oldPasswordController.text != currentPassword) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu cũ không chính xác!'), backgroundColor: Colors.red),
        );
        return;
      }

      if (_newPasswordController.text == currentPassword) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu mới phải khác mật khẩu cũ!'), backgroundColor: Colors.orange),
        );
        return;
      }

      await userDoc.reference.update({
        'pass': _newPasswordController.text,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('history').add({
        'type': 'account_update',
        'action': 'change_password',
        'description': 'Đổi mật khẩu tài khoản',
        'user_name': auth.userName,
        'created_at': FieldValue.serverTimestamp(),
      });

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đổi mật khẩu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildActivityLog() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NHẬT KỲ HOẠT ĐỘNG',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          // Table Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Nội Dung',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Thời Gian',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Loại',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Consumer<AuthService>(
            builder: (context, auth, _) {
              if (!auth.isLoggedIn) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Vui lòng đăng nhập để xem nhật ký.'),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('history')
                    .where('user_name', isEqualTo: auth.userName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Không thể tải nhật ký hoạt động.'),
                    );
                  }

                  final rows = (snapshot.data?.docs ?? []).toList()
                    ..sort((a, b) {
                      final aTs = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                      final bTs = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return 1;
                      if (bTs == null) return -1;
                      return bTs.compareTo(aTs);
                    });

                  final total = rows.length;
                  final totalPages = total == 0 ? 1 : (total / _activityPerPage).ceil();
                  final safePage = _activityPage > totalPages ? totalPages : _activityPage;
                  if (safePage != _activityPage) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _activityPage = safePage);
                    });
                  }
                  final start = (safePage - 1) * _activityPerPage;
                  final end = (start + _activityPerPage > total) ? total : start + _activityPerPage;
                  final pageItems = total == 0 ? <QueryDocumentSnapshot>[] : rows.sublist(start, end).cast<QueryDocumentSnapshot>();

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1),
                            right: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1),
                            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: pageItems.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                child: Center(child: Text('Chưa có hoạt động nào.')),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pageItems.length,
                                itemBuilder: (context, index) {
                                  final data = pageItems[index].data() as Map<String, dynamic>;
                                  final type = (data['type'] ?? 'account_update').toString();
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _activityTitle(data),
                                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            _formatDateTime(data['created_at'] as Timestamp?),
                                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            type,
                                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          Text(
                            total == 0
                                ? 'Hiển thị từ 0 đến 0 trong tổng số 0 kết quả'
                                : 'Hiển thị từ ${start + 1} đến $end trong tổng số $total kết quả',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            'Mỗi trang: $_activityPerPage',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: safePage > 1 ? () => setState(() => _activityPage--) : null,
                            color: Colors.orange.shade600,
                          ),
                          Container(
                            width: 60,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '$safePage/$totalPages',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: safePage < totalPages ? () => setState(() => _activityPage++) : null,
                            color: Colors.orange.shade600,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

}

