import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/background_music_service.dart';
import '../services/auth_service.dart';
import 'app_styles.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.constraints,
    this.padding,
    this.borderRadius = 30,
    this.useBlur = true,
  });

  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    final bool effectiveBlur = useBlur && !kIsWeb; 

    Widget content = Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: effectiveBlur ? 0.13 : 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
      ),
      child: child,
    );

    if (effectiveBlur) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}

class EffectPageScaffold extends StatelessWidget {
  const EffectPageScaffold({
    super.key,
    required this.topMenu,
    required this.body,
    this.backgroundOpacity = 0.8,
  });

  final Widget topMenu;
  final Widget body;
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Phần nền cố định phía sau
          Positioned.fill(
            child: Opacity(
              opacity: backgroundOpacity,
              child: Image.asset(
                'assets/images/anh-lien-quan-4k-thu-nguyen-ve-than-66.jpg',
                fit: BoxFit.cover,
                filterQuality: kIsWeb ? FilterQuality.none : FilterQuality.low,
              ),
            ),
          ),
          // Nội dung chính
          Column(
            children: [
              topMenu,
              Expanded(child: body),
            ],
          ),
          // Nút nhạc
          Positioned(
            bottom: isMobile ? 80 : null,
            top: isMobile ? null : 14,
            right: 14,
            child: const SafeArea(child: FloatingMusicButton()),
          ),
        ],
      ),
    );
  }
}

class AnimatedShopName extends StatelessWidget {
  const AnimatedShopName({super.key, this.fontSize = 22});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final topSize = fontSize * 0.9;
    final bottomSize = fontSize * 1.25;
    final height = math.max(bottomSize * 2.0, 52).toDouble();

    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8), Color(0xFF0284C7)],
            ).createShader(bounds),
            child: Text(
              'SHOP',
              style: TextStyle(
                fontSize: topSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFEA580C)],
            ).createShader(bounds),
            child: Text(
              'LIÊN QUÂN',
              style: TextStyle(
                fontSize: bottomSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                height: 1,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HoverMenuItem extends StatefulWidget {
  const HoverMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<HoverMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFFF97316).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: (_isHovered
                      ? const Color(0xFFF97316)
                      : Colors.black)
                  .withValues(alpha: _isHovered ? 0.35 : 0.18),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        transform: Matrix4.translationValues(0, _isHovered ? -1.2 : 0, 0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.transparent,
          splashColor: const Color(0xFFF97316).withValues(alpha: 0.18),
          highlightColor: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: const Color(0xFFF97316)),
                const SizedBox(width: 6),
              ],
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? Colors.white : const Color(0xFFFFF7ED),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserMenuButton extends StatefulWidget {
  final AuthService auth;
  const UserMenuButton({super.key, required this.auth});

  @override
  State<UserMenuButton> createState() => _UserMenuButtonState();
}

class _UserMenuButtonState extends State<UserMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        offset: const Offset(0, 10),
        color: Colors.white.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        ),
        onSelected: (value) {
          if (value == 'info') {
            Navigator.pushNamed(context, '/user-detail');
          } else if (value == 'logout') {
            widget.auth.logout();
          } else if (value == 'admin') {
            Navigator.pushNamed(context, '/admin-accounts');
          } else if (value == 'admin-users') {
            Navigator.pushNamed(context, '/admin-users');
          } else if (value == 'admin-stats') {
            Navigator.pushNamed(context, '/admin-stats');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _isHovered 
                ? Colors.white.withValues(alpha: 0.22) 
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered 
                  ? const Color(0xFFF97316).withValues(alpha: 0.95) 
                  : Colors.white.withValues(alpha: 0.28)
            ),
            boxShadow: [
              BoxShadow(
                color: (_isHovered ? const Color(0xFFF97316) : Colors.black).withValues(alpha: _isHovered ? 0.35 : 0.18),
                blurRadius: _isHovered ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          transform: Matrix4.translationValues(0, _isHovered ? -1.2 : 0, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle, size: 18, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              Text(
                widget.auth.userName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? Colors.white : const Color(0xFFFFF7ED),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: _isHovered ? Colors.white : const Color(0xFFFFF7ED), size: 18),
            ],
          ),
        ),
        itemBuilder: (context) => [
          if (widget.auth.isAdmin) ...[
            PopupMenuItem<String>(
              value: 'admin-stats',
              child: _buildPopupItem(Icons.bar_chart, 'Thống kê báo cáo'),
            ),
            PopupMenuItem<String>(
              value: 'admin',
              child: _buildPopupItem(Icons.settings, 'Quản lý tài khoản'),
            ),
            PopupMenuItem<String>(
              value: 'admin-users',
              child: _buildPopupItem(Icons.people, 'Quản lý người dùng'),
            ),
            const PopupMenuDivider(height: 1),
          ],
          PopupMenuItem<String>(
            value: 'info',
            child: _buildPopupItem(Icons.person, 'Thông tin người dùng'),
          ),
          PopupMenuItem<String>(
            value: 'logout',
            child: _buildPopupItem(Icons.logout, 'Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupItem(IconData icon, String title, {Color color = const Color(0xFFFFF7ED)}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

class DepositMenuButton extends StatelessWidget {
  const DepositMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      offset: const Offset(8, 10),
      color: Colors.white.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      onSelected: (value) {
        if (value == 'card') {
          Navigator.pushNamed(context, '/bank-card');
        } else if (value == 'atm') {
          Navigator.pushNamed(context, '/bank-atm');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'card',
          child: _buildPopupItem(Icons.style, 'Nạp tiền thẻ'),
        ),
        PopupMenuItem<String>(
          value: 'atm',
          child: _buildPopupItem(Icons.account_balance, 'Nạp tiền ATM'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, size: 18, color: Color(0xFFF97316)),
            SizedBox(width: 6),
            Text(
              'Nạp tiền',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFFF7ED)),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Color(0xFFFFF7ED)),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupItem(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFFF7ED)),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Color(0xFFFFF7ED), fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

class FloatingMusicButton extends StatelessWidget {
  const FloatingMusicButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundMusicService>(
      builder: (context, music, _) {
        return Tooltip(
          message: music.isPlaying ? 'Tắt nhạc nền' : 'Bật nhạc nền',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: music.toggle,
              icon: Icon(
                music.isPlaying ? Icons.album : Icons.album_outlined,
                color: const Color(0xFFF97316),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ExpandableContactButton extends StatefulWidget {
  const ExpandableContactButton({super.key});

  @override
  State<ExpandableContactButton> createState() => _ExpandableContactButtonState();
}

class _ExpandableContactButtonState extends State<ExpandableContactButton> {
  static const String _phoneNumber = '0383177942';
  static const String _facebookUrl = 'https://www.facebook.com/share/1FhMQ7L5BS/';

  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);

  Future<void> _openExternal(Uri uri, {required String fallbackMessage}) async {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!mounted || opened) return;
    _showMessage(fallbackMessage);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPhone() async {
    await _openExternal(
      Uri(scheme: 'tel', path: _phoneNumber),
      fallbackMessage: 'Không mở được trình gọi điện. Số liên hệ: $_phoneNumber',
    );
  }

  Future<void> _openFacebook() async {
    await _openExternal(
      Uri.parse(_facebookUrl),
      fallbackMessage: 'Không mở được Facebook. Link: $_facebookUrl',
    );
  }

  Future<void> _copyPhoneNumber() async {
    await Clipboard.setData(const ClipboardData(text: _phoneNumber));
    if (!mounted) return;
    _showMessage('Đã sao chép số liên hệ: $_phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: !_isOpen
                ? const SizedBox.shrink()
                : Column(
                    key: const ValueKey('contact_items'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _ContactRoundButton(
                        tooltip: 'Goi dien',
                        icon: Icons.phone_in_talk,
                        backgroundColor: const Color(0xFFF97316),
                        onTap: _openPhone,
                      ),
                      const SizedBox(height: 10),
                      _ContactRoundButton(
                        tooltip: 'Zalo',
                        label: 'Zalo',
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFF2563EB),
                        foregroundColor: const Color(0xFF2563EB),
                        onTap: _copyPhoneNumber,
                      ),
                      const SizedBox(height: 10),
                      _ContactRoundButton(
                        tooltip: 'Facebook',
                        icon: Icons.facebook,
                        backgroundColor: const Color(0xFF3B82F6),
                        onTap: _openFacebook,
                      ),
                      const SizedBox(height: 10),
                      _ContactRoundButton(
                        tooltip: 'Dong',
                        icon: Icons.close,
                        backgroundColor: const Color(0xFFEF4444),
                        onTap: _toggle,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 100,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Lien he',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRoundButton extends StatelessWidget {
  const _ContactRoundButton({
    required this.tooltip,
    required this.onTap,
    this.icon,
    this.label,
    this.backgroundColor = const Color(0xFFF97316),
    this.foregroundColor = Colors.white,
    this.borderColor,
  });

  final String tooltip;
  final FutureOr<void> Function() onTap;
  final IconData? icon;
  final String? label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            onTap();
          },
          child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor ?? Colors.transparent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: label != null
                    ? Text(
                        label!,
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                    : Icon(icon, color: foregroundColor, size: 24),
              )),
        ),
      ),
    );
  }
}
