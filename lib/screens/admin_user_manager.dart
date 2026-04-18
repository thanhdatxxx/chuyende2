import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/ui_effects.dart';
import '../widgets/app_styles.dart';
import '../widgets/home_footer.dart';
import '../widgets/top_menu.dart';

class AdminUserManager extends StatefulWidget {
  const AdminUserManager({super.key});

  @override
  State<AdminUserManager> createState() => _AdminUserManagerState();
}

class _AdminUserManagerState extends State<AdminUserManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  void _showUserDialog({Map<String, dynamic>? user, String? docId}) {
    final isEditing = user != null;
    final fullNameController = TextEditingController(text: isEditing ? user['full_name'] : '');
    final userNameController = TextEditingController(text: isEditing ? user['user_name'] : '');
    final emailController = TextEditingController(text: isEditing ? user['email'] : '');
    final passwordController = TextEditingController(text: isEditing ? user['pass'] : '');
    final balanceController = TextEditingController(text: isEditing ? user['balance'].toString() : '0');
    String selectedRole = isEditing ? (user['role'] ?? 'user') : 'user';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Chỉnh sửa người dùng' : 'Thêm người dùng mới',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                _buildField(fullNameController, 'Họ tên *', Icons.person),
                _buildField(userNameController, 'Tên đăng nhập *', Icons.account_circle),
                _buildField(emailController, 'Email *', Icons.email),
                _buildField(passwordController, 'Mật khẩu *', Icons.vpn_key),
                _buildField(balanceController, 'Số dư (vnđ) *', Icons.account_balance_wallet, isNumber: true),
                
                const Text('Vai trò', style: TextStyle(color: Colors.white70, fontSize: 14)),
                StatefulBuilder(
                  builder: (context, setInnerState) => DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Người dùng (User)')),
                      DropdownMenuItem(value: 'admin', child: Text('Quản trị (Admin)')),
                    ],
                    onChanged: (v) => setInnerState(() => selectedRole = v!),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.security, color: AppStyles.primaryColor, size: 20),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.white70))),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      onPressed: () async {
                        final fullName = fullNameController.text.trim();
                        final userName = userNameController.text.trim();
                        final email = emailController.text.trim();
                        final password = passwordController.text;

                        if (fullName.isEmpty || userName.isEmpty || email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin bắt buộc'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }

                        final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
                        final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
                        final hasLowercase = RegExp(r'[a-z]').hasMatch(password);

                        if (!emailRegex.hasMatch(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email không hợp lệ. Ví dụ: tenban@gmail.com'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        if (password.length < 6 || !hasUppercase || !hasLowercase) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mật khẩu phải từ 6 ký tự và có cả chữ hoa + chữ thường!'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        final data = {
                          'full_name': fullName,
                          'user_name': userName,
                          'email': email,
                          'pass': password,
                          'balance': double.tryParse(balanceController.text) ?? 0,
                          'role': selectedRole,
                          'updated_at': FieldValue.serverTimestamp(),
                        };

                        try {
                          if (isEditing) {
                            await _firestore.collection('user').doc(docId).update(data);
                          } else {
                            data['deposited_money'] = 0.0;
                            data['created_at'] = FieldValue.serverTimestamp();
                            await _firestore.collection('user').add(data);
                          }
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        }
                      },
                      child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: AppStyles.primaryColor, size: 20),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppStyles.primaryColor)),
        ),
      ),
    );
  }

  void _deleteUser(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: const Text('Xóa người dùng này? Thao tác này không thể hoàn tác.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa người dùng'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('user').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'QUẢN LÝ NGƯỜI DÙNG', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)
                ),
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                padding: const EdgeInsets.all(15),
                constraints: const BoxConstraints(maxWidth: 1200),
                decoration: AppStyles.glassContainerDecoration,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Tìm theo tên hoặc tài khoản...",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          prefixIcon: const Icon(Icons.search, color: AppStyles.primaryColor),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() => _currentPage = 1),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white30),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _currentPage = 1);
                      },
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('THÊM NGƯỜI DÙNG MỚI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => _showUserDialog(),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('user').orderBy('created_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final searchText = _searchController.text.toLowerCase();
                final allDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['full_name'] ?? '').toString().toLowerCase();
                  final user = (data['user_name'] ?? '').toString().toLowerCase();
                  return name.contains(searchText) || user.contains(searchText);
                }).toList();

                final totalPages = (allDocs.length / _itemsPerPage).ceil();
                final startIndex = (_currentPage - 1) * _itemsPerPage;
                final endIndex = startIndex + _itemsPerPage;
                final visibleDocs = allDocs.sublist(
                  startIndex, 
                  endIndex > allDocs.length ? allDocs.length : endIndex
                );

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: visibleDocs.length,
                      itemBuilder: (context, index) {
                        final doc = visibleDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final role = data['role'] == 'admin' ? 'Quản trị' : 'Người dùng';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassContainer(
                            borderRadius: 15,
                            padding: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: data['role'] == 'admin' ? Colors.orange : Colors.blue,
                                child: Text(data['full_name']?[0]?.toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(
                                '${data['full_name']} (@${data['user_name']})',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Email: ${data['email']} | Số dư: ${data['balance']}đ\nQuyền: $role',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showUserDialog(user: data, docId: doc.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                    onPressed: () => _deleteUser(doc.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPageButton(
                              icon: Icons.arrow_back_ios,
                              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                            ),
                            const SizedBox(width: 20),
                            Text('Trang $_currentPage / $totalPages', style: const TextStyle(color: Colors.white)),
                            const SizedBox(width: 20),
                            _buildPageButton(
                              icon: Icons.arrow_forward_ios,
                              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 50),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: onPressed == null ? Colors.white24 : Colors.white, size: 18),
      style: IconButton.styleFrom(backgroundColor: Colors.white10),
    );
  }
}
