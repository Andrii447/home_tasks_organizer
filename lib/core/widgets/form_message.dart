import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum FormMessageType { error, success }

/// Повідомлення над кнопкою форми: помилка запиту або успіх.
class FormMessage extends StatelessWidget {
  const FormMessage(this.text, {super.key, this.type = FormMessageType.error});

  final String text;
  final FormMessageType type;

  @override
  Widget build(BuildContext context) {
    final isError = type == FormMessageType.error;
    final fg = isError ? AppColors.danger : AppColors.completedFg;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isError ? AppColors.dangerSoft : AppColors.completedBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: fg,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: fg, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
