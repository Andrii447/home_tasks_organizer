import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Стилізоване текстове поле.
///
/// * за замовчуванням підпис «вирізає» рамку (екрани авторизації);
/// * `labelAbove` — підпис над полем (форми, профіль);
/// * `obscure` — поле пароля з кнопкою показу/приховування.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.enabled = true,
    this.labelAbove = false,
    this.required = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final bool enabled;
  final bool labelAbove;
  final bool required;
  final int maxLines;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  Widget? _suffix() {
    if (widget.obscure) {
      return IconButton(
        tooltip: _hidden ? 'Показати пароль' : 'Сховати пароль',
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
      );
    }
    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      obscureText: _hidden,
      enabled: widget.enabled,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelAbove ? null : widget.label,
        hintText: widget.hint,
        suffixIcon: _suffix(),
        fillColor: widget.enabled ? null : AppColors.disabledField,
      ),
    );

    if (!widget.labelAbove) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            children: [
              if (widget.required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
            ],
          ),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
