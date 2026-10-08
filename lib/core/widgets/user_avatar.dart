import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Коло з першою літерою імені (заглушка замість фото профілю).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.radius = 14});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.selected,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
