import 'package:flutter/material.dart';

/// 次元链接二次元配色：樱花粉、星空紫、薄荷青。
class AppColors {
  AppColors._();

  static const Color sakura = Color(0xFFFF6B9D);
  static const Color sakuraSoft = Color(0xFFFFC2D4);
  static const Color starPurple = Color(0xFF7C6CFF);
  static const Color starPurpleSoft = Color(0xFFC9C2FF);
  static const Color mint = Color(0xFF5EEAD4);
  static const Color peach = Color(0xFFFFB38A);
  static const Color lemon = Color(0xFFFFE08A);
  static const Color sky = Color(0xFF8EC5FF);

  static const Color ink = Color(0xFF3D2C4A);
  static const Color inkMuted = Color(0xFF8A7A96);
  static const Color cream = Color(0xFFFFF7FB);
  static const Color lilacMist = Color(0xFFF3EEFF);
  static const Color card = Color(0xFFFFFFF8);
  static const Color line = Color(0x1A3D2C4A);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE4F0), Color(0xFFE8E0FF), Color(0xFFD9FFF6)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [sakura, starPurple],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1848), Color(0xFF5A2D6E), Color(0xFFFF8FB8)],
  );

  static const List<Color> avatarPalette = [
    sakura,
    starPurple,
    mint,
    peach,
    sky,
    Color(0xFFFF8AC8),
    Color(0xFF8A7CFF),
    Color(0xFF6BE0C8),
  ];
}
