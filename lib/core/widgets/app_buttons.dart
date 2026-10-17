import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Основна заповнена кнопка (зелена, «пігулка»).
///
/// `loading` показує індикатор і блокує повторне натискання.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    final Widget button;
    if (loading) {
      button = FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
        ),
        child: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Colors.white,
          ),
        ),
      );
    } else if (icon == null) {
      button = FilledButton(onPressed: onTap, child: Text(label));
    } else {
      button = FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
      );
    }
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
