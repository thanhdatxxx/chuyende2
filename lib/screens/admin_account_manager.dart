import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/ui_effects.dart';
import '../widgets/app_styles.dart';
import '../widgets/filter_bar.dart';
import '../widgets/home_footer.dart';
import '../widgets/top_menu.dart';

class AdminAccountManager extends StatefulWidget {
  const AdminAccountManager({super.key});

  @override
  State<AdminAccountManager> createState() => _AdminAccountManagerState();
}

class _AdminAccountManagerState extends State<AdminAccountManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedRankFilter = 'Tất cả';
  final List<String> _ranks = ['Tất cả', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Tinh Anh', 'Cao Thủ', 'Chiến Tướng', 'Thách Đấu'];

  final Map<String, String> _statusMapping = {
    'Sẵn sàng': 'available',
    'Đã bán': 'sold',
    'available': 'available',
    'sold': 'sold',
  };

  final Map<String, String> _displayStatus = {
    'available': 'Sẵn sàng',
    'sold': 'Đã bán',
  };

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.startsWith('http') && 
           (lowercaseUrl.contains('.jpg') || 
            lowercaseUrl.contains('.jpeg') || 
            lowercaseUrl.contains('.png') || 
            lowercaseUrl.contains('.webp') ||
            lowercaseUrl.contains('firebasestorage'));
  }

  void _showAccountDialog({Map<String, dynamic>? account, String? docId}) {
    final isEditing = account != null;
    final priceController = TextEditingController(text: isEditing ? account['price'].toString() : '');
    final heroController = TextEditingController(text: isEditing ? account['hero_count'].toString() : '');
    final skinController = TextEditingController(text: isEditing ? account['skin_count'].toString() : '');
    final imageController = TextEditingController(text: isEditing ? account['image_url'] : '');
    final descriptionController = TextEditingController(text: isEditing ? account['description'] : '');
    final tkController = TextEditingController(text: isEditing ? account['taikhoan'] : '');
    final mkController = TextEditingController(text: isEditing ? account['matkhau'] : '');
    
    List<String> rankOptions = List.from(_ranks)..remove('Tất cả');
    String selectedRank = isEditing && rankOptions.contains(account['rank']) ? account['rank'] : rankOptions[0];
    
    String rawStatus = account?['status']?.toString() ?? 'available';
    String selectedStatus = _statusMapping[rawStatus] ?? 'available';

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
                  isEditing ? 'Chỉnh sửa tài khoản' : 'Thêm tài khoản mới',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                _buildField(priceController, 'Giá (vnđ) *', Icons.attach_money, isNumber: true),
                
                const Text('Hạng (Rank) *', style: TextStyle(color: Colors.white70, fontSize: 14)),
                StatefulBuilder(
                  builder: (context, setInnerState) => DropdownButtonFormField<String>(
                    value: selectedRank,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: rankOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setInnerState(() => selectedRank = v!),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.emoji_events, color: AppStyles.primaryColor, size: 20),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                _buildField(heroController, 'Số tướng *', Icons.person, isNumber: true),
                _buildField(skinController, 'Số trang phục *', Icons.checkroom, isNumber: true),
                _buildField(imageController, 'Link ảnh *', Icons.image),
                _buildField(tkController, 'Tài khoản (để bàn giao) *', Icons.account_box),
                _buildField(mkController, 'Mật khẩu (để bàn giao) *', Icons.vpn_key),
                _buildField(descriptionController, 'Mô tả', Icons.description, maxLines: 3),
                
                const Text('Trạng thái', style: TextStyle(color: Colors.white70, fontSize: 14)),
                StatefulBuilder(
                  builder: (context, setInnerState) => DropdownButtonFormField<String>(
                    value: selectedStatus,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'available', child: Text('Sẵn sàng')),
                      DropdownMenuItem(value: 'sold', child: Text('Đã bán')),
                    ],
                    onChanged: (v) => setInnerState(() => selectedStatus = v!),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.info_outline, color: AppStyles.primaryColor, size: 20),
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
                        if (priceController.text.isEmpty || 
                            heroController.text.isEmpty || 
                            skinController.text.isEmpty || 
                            imageController.text.isEmpty || 
                            tkController.text.isEmpty || 
                            mkController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập đầy đủ các trường có dấu *'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }

                        if (!_isValidImageUrl(imageController.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link ảnh không hợp lệ! Vui lòng nhập link kết thúc bằng .jpg, .png, .webp...'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        final data = {
                          'price': double.tryParse(priceController.text) ?? 0,
                          'rank': selectedRank,
                          'hero_count': int.tryParse(heroController.text) ?? 0,
                          'skin_count': int.tryParse(skinController.text) ?? 0,
                          'image_url': imageController.text,
                          'description': descriptionController.text,
                          'taikhoan': tkController.text,
                          'matkhau': mkController.text,
                          'status': selectedStatus,
                          'updated_at': FieldValue.serverTimestamp(),
                        };

                        try {
                          if (isEditing) {
                            await _firestore.collection('accounts').doc(docId).update(data);
                          } else {
                            data['created_at'] = FieldValue.serverTimestamp();
                            await _firestore.collection('accounts').add(data);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã lưu thành công!'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                            );
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

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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

  void _deleteAccount(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản này khỏi hệ thống?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('accounts').doc(docId).delete();
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
                  'QUẢN TRỊ VIÊN', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)
                ),
              ),
            ),
            FilterBar(
              selectedRank: _selectedRankFilter,
              ranks: _ranks,
              minPriceController: _minPriceController,
              maxPriceController: _maxPriceController,
              onRankChanged: (v) => setState(() { _selectedRankFilter = v; _currentPage = 1; }),
              onSearch: () => setState(() => _currentPage = 1),
              onClear: () => setState(() {
                _minPriceController.clear();
                _maxPriceController.clear();
                _selectedRankFilter = 'Tất cả';
                _currentPage = 1;
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showAccountDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.white),
                        SizedBox(width: 10),
                        Text('THÊM TÀI KHOẢN MỚI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('accounts').orderBy('created_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                double minPrice = double.tryParse(_minPriceController.text) ?? 0;
                double maxPrice = double.tryParse(_maxPriceController.text) ?? double.infinity;
                
                final allDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final price = (data['price'] ?? 0).toDouble();
                  final rank = (data['rank'] ?? '').toString();
                  
                  bool rankMatch = _selectedRankFilter == 'Tất cả' || rank.contains(_selectedRankFilter);
                  bool priceMatch = price >= minPrice && price <= maxPrice;
                  
                  return rankMatch && priceMatch;
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
                        final status = _displayStatus[data['status']] ?? data['status'] ?? 'Sẵn sàng';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassContainer(
                            borderRadius: 15,
                            padding: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['image_url'] ?? '',
                                  width: 60, height: 60, fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white30)),
                                ),
                              ),
                              title: Text(
                                'Rank: ${data['rank']} - ${data['price']}đ',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Tướng: ${data['hero_count']} | Skin: ${data['skin_count']} | Trạng thái: $status',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 28),
                                    onPressed: () => _showAccountDialog(account: data, docId: doc.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
                                    onPressed: () => _deleteAccount(doc.id),
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
                              icon: Icons.arrow_back_ios_new_rounded,
                              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                            ),
                            const SizedBox(width: 20),
                            Text(
                              'Trang $_currentPage / $totalPages',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 20),
                            _buildPageButton(
                              icon: Icons.arrow_forward_ios_rounded,
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
      icon: Icon(icon, color: onPressed == null ? Colors.white24 : Colors.white, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
