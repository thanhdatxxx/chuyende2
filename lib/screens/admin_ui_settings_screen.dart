import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ui_settings_service.dart';
import '../services/background_music_service.dart';
import '../widgets/ui_effects.dart';
import '../widgets/app_styles.dart';
import '../widgets/home_footer.dart';
import '../widgets/top_menu.dart';

class AdminUiSettingsScreen extends StatefulWidget {
  const AdminUiSettingsScreen({super.key});

  @override
  State<AdminUiSettingsScreen> createState() => _AdminUiSettingsScreenState();
}

class _AdminUiSettingsScreenState extends State<AdminUiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _footerDescController;
  late TextEditingController _footerPhoneController;
  late TextEditingController _footerEmailController;
  late TextEditingController _footerLocController;
  late TextEditingController _footerCopyController;
  late TextEditingController _bgController;

  List<TextEditingController> _bannerControllers = [];
  List<TextEditingController> _musicControllers = [];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final uiSettings = context.read<UiSettingsService>();
      
      _footerDescController = TextEditingController(text: uiSettings.footerDescription);
      _footerPhoneController = TextEditingController(text: uiSettings.footerPhone);
      _footerEmailController = TextEditingController(text: uiSettings.footerEmail);
      _footerLocController = TextEditingController(text: uiSettings.footerLocation);
      _footerCopyController = TextEditingController(text: uiSettings.footerCopyright);
      _bgController = TextEditingController(text: uiSettings.backgroundImage);

      _bannerControllers = uiSettings.banners
          .map((banner) => TextEditingController(text: banner))
          .toList();

      _musicControllers = uiSettings.musicTracks
          .map((track) => TextEditingController(text: track))
          .toList();

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _footerDescController.dispose();
    _footerPhoneController.dispose();
    _footerEmailController.dispose();
    _footerLocController.dispose();
    _footerCopyController.dispose();
    _bgController.dispose();
    for (var c in _bannerControllers) {
      c.dispose();
    }
    for (var c in _musicControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addBannerField() {
    setState(() {
      _bannerControllers.add(TextEditingController());
    });
  }

  void _removeBannerField(int index) {
    setState(() {
      _bannerControllers[index].dispose();
      _bannerControllers.removeAt(index);
    });
  }

  void _addMusicField() {
    setState(() {
      _musicControllers.add(TextEditingController());
    });
  }

  void _removeMusicField(int index) {
    setState(() {
      _musicControllers[index].dispose();
      _musicControllers.removeAt(index);
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final uiSettings = context.read<UiSettingsService>();
    final musicService = context.read<BackgroundMusicService>();

    final banners = _bannerControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final music = _musicControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (banners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 ảnh banner!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (music.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 bài nhạc nền!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await uiSettings.saveSettings(
      banners: banners,
      music: music,
      backgroundImage: _bgController.text.trim(),
      footerDescription: _footerDescController.text.trim(),
      footerPhone: _footerPhoneController.text.trim(),
      footerEmail: _footerEmailController.text.trim(),
      footerLocation: _footerLocController.text.trim(),
      footerCopyright: _footerCopyController.text.trim(),
    );

    if (success) {
      // Cập nhật nhạc nền chạy trực tiếp nếu đang phát
      await musicService.updatePlaylist(music);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu cấu hình giao diện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu cấu hình giao diện thất bại!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận khôi phục', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn khôi phục giao diện về mặc định gốc?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uiSettings = context.read<UiSettingsService>();
      final musicService = context.read<BackgroundMusicService>();

      final success = await uiSettings.resetToDefault();
      if (success) {
        await musicService.updatePlaylist(uiSettings.musicTracks);

        setState(() {
          _bgController.text = uiSettings.backgroundImage;
          _footerDescController.text = uiSettings.footerDescription;
          _footerPhoneController.text = uiSettings.footerPhone;
          _footerEmailController.text = uiSettings.footerEmail;
          _footerLocController.text = uiSettings.footerLocation;
          _footerCopyController.text = uiSettings.footerCopyright;

          for (var c in _bannerControllers) {
            c.dispose();
          }
          _bannerControllers = uiSettings.banners
              .map((banner) => TextEditingController(text: banner))
              .toList();

          for (var c in _musicControllers) {
            c.dispose();
          }
          _musicControllers = uiSettings.musicTracks
              .map((track) => TextEditingController(text: track))
              .toList();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã khôi phục giao diện mặc định!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final uiSettings = context.watch<UiSettingsService>();

    return EffectPageScaffold(
      topMenu: const TopMenu(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'TÙY CHỈNH GIAO DIỆN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Form(
                      key: _formKey,
                      child: Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: Banner list and Music list
                          _buildResponsiveColumn(
                            isMobile: isMobile,
                            child: Column(
                              children: [
                                _buildBannerSection(),
                                const SizedBox(height: 20),
                                _buildMusicSection(),
                                if (isMobile) const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          if (!isMobile) const SizedBox(width: 20),
                          // Right column: Footer configurations
                          _buildResponsiveColumn(
                            isMobile: isMobile,
                            child: Column(
                              children: [
                                _buildBackgroundSection(),
                                const SizedBox(height: 20),
                                _buildFooterSection(),
                                const SizedBox(height: 25),
                                _buildActionButtons(uiSettings.isLoading),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                const HomeFooter(),
              ],
            ),
          ),
          if (uiSettings.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: AppStyles.primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: AppStyles.primaryColor, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ẢNH BANNERS QUẢNG CÁO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addBannerField,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bannerControllers.length,
            itemBuilder: (context, index) {
              final controller = _bannerControllers[index];
              final text = controller.text.trim();
              final isNetworkImage = text.startsWith('http') || text.startsWith('https');

              return Card(
                key: ValueKey(controller),
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Nhập đường dẫn ảnh (Asset hoặc URL)...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppStyles.primaryColor),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Không được để trống' : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () => _removeBannerField(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Image Preview
                      if (text.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: Colors.black26,
                            child: isNetworkImage
                                ? Image.network(
                                    text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(
                                      child: Text(
                                        'Lỗi tải ảnh (URL không hợp lệ)',
                                        style: TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(
                                      child: Text(
                                        'Lỗi tải ảnh (Asset không hợp lệ)',
                                        style: TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    ),
                                  ),
                          ),
                        )
                      else
                        const Text(
                          'Chưa có đường dẫn ảnh',
                          style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMusicSection() {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: AppStyles.primaryColor, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'DANH SÁCH NHẠC NỀN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addMusicField,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _musicControllers.length,
            itemBuilder: (context, index) {
              final controller = _musicControllers[index];
              return Padding(
                key: ValueKey(controller),
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Đường dẫn file nhạc (Asset/URL)...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppStyles.primaryColor),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Không được để trống' : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeMusicField(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundSection() {
    final text = _bgController.text.trim();
    final isNetworkImage = text.startsWith('http') || text.startsWith('https');

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wallpaper, color: AppStyles.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                'HÌNH NỀN TRANG WEB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _bgController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Đường dẫn hình nền (Asset hoặc URL)',
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
              hintText: 'Nhập URL ảnh nền hoặc đường dẫn asset...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              prefixIcon: const Icon(Icons.link, color: AppStyles.primaryColor, size: 20),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppStyles.primaryColor),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.redAccent),
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Trường này bắt buộc' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 15),
          if (text.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: isNetworkImage
                    ? Image.network(
                        text,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text(
                            'Lỗi tải ảnh từ URL',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      )
                    : Image.asset(
                        text,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text(
                            'Lỗi tải ảnh từ Asset',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: AppStyles.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                'THÔNG TIN FOOTER & LIÊN HỆ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _footerDescController,
            label: 'Giới thiệu ngắn về Shop',
            icon: Icons.description,
            maxLines: 3,
          ),
          _buildTextField(
            controller: _footerPhoneController,
            label: 'Số điện thoại liên hệ',
            icon: Icons.phone,
          ),
          _buildTextField(
            controller: _footerEmailController,
            label: 'Email hỗ trợ',
            icon: Icons.email,
          ),
          _buildTextField(
            controller: _footerLocController,
            label: 'Địa chỉ / Khu vực',
            icon: Icons.location_on,
          ),
          _buildTextField(
            controller: _footerCopyController,
            label: 'Bản quyền (Copyright)',
            icon: Icons.copyright,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          prefixIcon: Icon(icon, color: AppStyles.primaryColor, size: 20),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppStyles.primaryColor),
          ),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Trường này bắt buộc' : null,
      ),
    );
  }

  Widget _buildActionButtons(bool isLoading) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    final buttons = [
      ElevatedButton.icon(
        onPressed: isLoading ? null : _resetToDefault,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Khôi phục mặc định'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      SizedBox(width: isMobile ? 0 : 15, height: isMobile ? 12 : 0),
      ElevatedButton.icon(
        onPressed: isLoading ? null : _saveSettings,
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Lưu thay đổi'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: buttons,
    );
  }

  Widget _buildResponsiveColumn({required bool isMobile, required Widget child}) {
    if (isMobile) return child;
    return Expanded(child: child);
  }
}
