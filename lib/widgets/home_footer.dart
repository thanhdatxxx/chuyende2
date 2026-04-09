import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'ui_effects.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFlexibleColumn(
                    isMobile: isMobile,
                    flex: 2,
                    child: _buildShopInfo(),
                  ),
                  if (isMobile) const SizedBox(height: 30) else const SizedBox(width: 30),
                  _buildFlexibleColumn(
                    isMobile: isMobile,
                    flex: 1,
                    child: _buildContactInfo(),
                  ),
                  if (isMobile) const SizedBox(height: 30),
                  _buildFlexibleColumn(
                    isMobile: isMobile,
                    flex: 1,
                    child: _buildSocialInfo(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 15),
              Text(
                "© 2024 LIENQUAN SHOP VN - All Rights Reserved.",
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlexibleColumn({required bool isMobile, required int flex, required Widget child}) {
    if (isMobile) return SizedBox(width: double.infinity, child: child);
    return Expanded(flex: flex, child: child);
  }

  Widget _buildShopInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gamepad, color: AppStyles.primaryColor, size: 24),
            SizedBox(width: 8),
            AnimatedShopName(),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "Hệ thống bán tài khoản Liên Quân Mobile uy tín, chất lượng hàng đầu Việt Nam. Giao dịch tự động 24/7.",
          style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LIÊN HỆ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _footerRow(Icons.phone, "0987.654.321"),
        _footerRow(Icons.email, "support@lienquanshop.vn"),
        _footerRow(Icons.location_on, "Hà Nội, Việt Nam"),
      ],
    );
  }

  Widget _buildSocialInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("KẾT NỐI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          children: [
            _socialIcon(Icons.facebook, Colors.blue),
            _socialIcon(Icons.video_library, Colors.red),
            _socialIcon(Icons.discord, Colors.indigoAccent),
          ],
        ),
      ],
    );
  }

  Widget _footerRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade400, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
