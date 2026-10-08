import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Рядок на кшталт «Ще не маєте акаунта? Зареєструватися».
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
