import 'package:flutter/material.dart';

/// Палітра ДімПлан, зняти з макетів лабораторної роботи №2.
abstract final class AppColors {
  static const primary = Color(0xFF4F7F5F);
  static const background = Color(0xFFF5F7F4);
  static const surface = Colors.white;
  static const sidebar = Color(0xFFEEF3ED);
  static const selected = Color(0xFFE5EFE7);

  static const outline = Color(0xFFDCDFDB);
  static const fieldBorder = Color(0xFF7A817C);
  static const disabledField = Color(0xFFE9ECE9);

  static const textPrimary = Color(0xFF181C19);
  static const textSecondary = Color(0xFF5F665F);

  static const danger = Color(0xFF9E4A44);
  static const dangerSoft = Color(0xFFF8E9E4);

  static const plannedBg = Color(0xFFE8EAF1);
  static const plannedFg = Color(0xFF555A6F);
  static const inProgressBg = Color(0xFFFBEFD2);
  static const inProgressFg = Color(0xFF866727);
  static const completedBg = Color(0xFFDDEEE2);
  static const completedFg = Color(0xFF3C6B4B);
}
