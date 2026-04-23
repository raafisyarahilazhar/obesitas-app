import 'package:flutter/material.dart';

class AppColors {
  // ── Core Palette ─────────────────────────────────────────────────
  static const Color bg       = Color(0xFFF7F7F7);   // Light gray background
  static const Color card     = Color(0xFFFFFFFF);   // White cards
  static const Color accent   = Color(0xFFD32F2F);   // Deep red primary
  static const Color accentDark = Color(0xFFB71C1C); // Darker red (gradient)
  static const Color accentLight = Color(0xFFFFEBEE); // Very light red bg
  static const Color textPri  = Color(0xFF1C1C1E);   // Near-black text
  static const Color textSub  = Color(0xFF8E8E93);   // Gray secondary text
  static const Color border   = Color(0xFFF0F0F0);   // Light border
  static const Color shadow   = Color(0x14000000);   // Subtle shadow

  // ── Semantic Colors ───────────────────────────────────────────────
  static const Color success  = Color(0xFF2E7D32);
  static const Color warning  = Color(0xFFF57C00);
  static const Color danger   = Color(0xFFD32F2F);
  static const Color info     = Color(0xFF1565C0);

  // ── Gradient ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBg = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFF7F0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}