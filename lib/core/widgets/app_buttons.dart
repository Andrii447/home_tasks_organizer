import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Основна заповнена кнопка (зелена, «пігулка»).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final text = Text(label);
    final button = icon == null
        ? FilledButton(onPressed: onPressed, child: text)
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: text,
          );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Другорядна кнопка з контуром; `danger` — для небезпечних дій (вихід).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final style = danger
        ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger)
        : null;
    final text = Text(label);
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: text)
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: text,
          );
  }
}
