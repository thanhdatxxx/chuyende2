import 'package:flutter/material.dart';

class AppStyles {
  // Colors
  static const Color primaryColor = Color(0xFFF97316);
  static const Color secondaryColor = Color(0xFF1E293B);
  static const Color backgroundColor = Colors.black;
  static const Color textColorPrimary = Color(0xFFFFF7ED);
  static const Color textColorSecondary = Colors.white70;
  static const Color glassBorderColor = Colors.white24;

  // Gradients
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  // Text Styles
  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle accountCardTitleStyle = TextStyle(
    fontSize: 11,
    color: Colors.black54,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle accountPriceStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.bold,
    fontSize: 17,
  );

  static const TextStyle accountInfoLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black54,
  );

  static const TextStyle accountValueStyle = TextStyle(
    fontSize: 13,
    color: Colors.grey,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle footerTitleStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle footerLinkStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  // Decorations
  static BoxDecoration glassContainerDecoration = BoxDecoration(
    color: secondaryColor.withOpacity(0.6),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.15)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
      )
    ],
  );

  static BoxDecoration accountCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.grey.shade200),
  );
}
