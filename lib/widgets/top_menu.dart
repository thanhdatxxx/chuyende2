import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'ui_effects.dart';
import 'app_styles.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isMobile = sw < 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 20, 
        vertical: isMobile ? 10 : 20
      ),
      child: Center(
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24, 
            vertical: isMobile ? 8 : 12
          ),
          child: Row(
            children: [
              // Logo: Icon Gamepad + Shop Name
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gamepad, 
                      color: AppStyles.primaryColor, 
                      size: isMobile ? 24 : 28
                    ),
                    const SizedBox(width: 8),
                    AnimatedShopName(fontSize: isMobile ? 18 : 22),
                  ],
                ),
              ),
              const Spacer(),
              if (isMobile)
                _buildMobileMenu(context)
              else
                _buildDesktopMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          return Row(
            children: [
              HoverMenuItem(
                title: 'Đăng ký',
                onTap: () => Navigator.pushNamed(context, '/register'),
              ),
              const SizedBox(width: 25),
              HoverMenuItem(
                title: 'Đăng nhập',
                onTap: () => Navigator.pushNamed(context, '/login'),
              ),
            ],
          );
        }
        return Row(
          children: [
            HoverMenuItem(
              title: 'Trang chủ',
              icon: Icons.home,
              onTap: () => Navigator.pushNamed(context, '/'),
            ),
            if (!auth.isAdmin) ...[
              const SizedBox(width: 20),
              HoverMenuItem(
                title: 'Lịch sử',
                icon: Icons.history,
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
              const SizedBox(width: 20),
              const DepositMenuButton(),
            ],
            const SizedBox(width: 30),
            UserMenuButton(auth: auth),
          ],
        );
      },
    );
  }

  Widget _buildMobileMenu(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          color: Colors.white.withValues(alpha: 0.16), // Liquid Glass
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),
          onSelected: (value) {
            if (value == 'home') Navigator.pushNamed(context, '/');
            if (value == 'login') Navigator.pushNamed(context, '/login');
            if (value == 'register') Navigator.pushNamed(context, '/register');
            if (value == 'history') Navigator.pushNamed(context, '/history');
            if (value == 'deposit_card') Navigator.pushNamed(context, '/bank-card');
            if (value == 'deposit_atm') Navigator.pushNamed(context, '/bank-atm');
            if (value == 'user_info') Navigator.pushNamed(context, '/user-detail');
            if (value == 'admin_acc') Navigator.pushNamed(context, '/admin-accounts');
            if (value == 'admin_user') Navigator.pushNamed(context, '/admin-users');
            if (value == 'logout') auth.logout();
          },
          itemBuilder: (context) => [
            if (!auth.isLoggedIn) ...[
              const PopupMenuItem(value: 'login', child: Text('Đăng nhập', style: TextStyle(color: Color(0xFFFFF7ED)))),
              const PopupMenuItem(value: 'register', child: Text('Đăng ký', style: TextStyle(color: Color(0xFFFFF7ED)))),
            ] else ...[
              const PopupMenuItem(value: 'home', child: Text('Trang chủ', style: TextStyle(color: Color(0xFFFFF7ED)))),
              if (!auth.isAdmin) ...[
                const PopupMenuItem(value: 'history', child: Text('Lịch sử mua', style: TextStyle(color: Color(0xFFFFF7ED)))),
                const PopupMenuItem(value: 'deposit_card', child: Text('Nạp tiền thẻ', style: TextStyle(color: Color(0xFFFFF7ED)))),
                const PopupMenuItem(value: 'deposit_atm', child: Text('Nạp tiền ATM', style: TextStyle(color: Color(0xFFFFF7ED)))),
              ],
              if (auth.isAdmin) ...[
                const PopupMenuItem(value: 'admin_acc', child: Text('Quản lý tài khoản', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                const PopupMenuItem(value: 'admin_user', child: Text('Quản lý người dùng', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
              ],
              const PopupMenuItem(value: 'user_info', child: Text('Thông tin cá nhân', style: TextStyle(color: Color(0xFFFFF7ED)))),
              const PopupMenuItem(value: 'logout', child: Text('Đăng xuất', style: TextStyle(color: Colors.orangeAccent))),
            ],
          ],
        );
      },
    );
  }
}
