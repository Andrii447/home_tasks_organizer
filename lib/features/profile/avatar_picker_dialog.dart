import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';

/// Готові аватари з HTTPS-посиланнями (DiceBear, дозволяє CORS для Web).
const presetAvatars = [
  'https://api.dicebear.com/9.x/thumbs/png?seed=Andrii&size=128',
  'https://api.dicebear.com/9.x/thumbs/png?seed=Maria&size=128',
  'https://api.dicebear.com/9.x/thumbs/png?seed=Oleh&size=128',
  'https://api.dicebear.com/9.x/fun-emoji/png?seed=Home&size=128',
  'https://api.dicebear.com/9.x/fun-emoji/png?seed=Plan&size=128',
  'https://api.dicebear.com/9.x/bottts-neutral/png?seed=Dim&size=128',
];

/// Вибір фото профілю: з набору готових зображень або власне
/// HTTPS-посилання з попереднім переглядом. Повертає URL або null.
Future<String?> showAvatarPickerDialog(
  BuildContext context, {
  required String name,
  String? current,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AvatarPickerDialog(name: name, current: current),
  );
}

class _AvatarPickerDialog extends StatefulWidget {
  const _AvatarPickerDialog({required this.name, this.current});

  final String name;
  final String? current;

  @override
  State<_AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<_AvatarPickerDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selected = widget.current;
  late final _url = TextEditingController(
    text: presetAvatars.contains(widget.current) ? '' : widget.current,
  );

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _applyCustomUrl() {
    if (_formKey.currentState!.validate()) {
      setState(() => _selected = _url.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Фото профілю',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Оберіть готове зображення або вставте власне HTTPS-посилання.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: UserAvatar(
                  name: widget.name,
                  photoUrl: _selected,
                  radius: 44,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final url in presetAvatars)
                    _AvatarOption(
                      url: url,
                      name: widget.name,
                      selected: url == _selected,
                      onTap: () => setState(() => _selected = url),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: AppTextField(
                  label: 'Власне посилання',
                  labelAbove: true,
                  controller: _url,
                  hint: 'https://…/photo.png',
                  keyboardType: TextInputType.url,
                  validator: Validators.httpsUrl,
                  onSubmitted: (_) => _applyCustomUrl(),
                  suffixIcon: IconButton(
                    tooltip: 'Попередній перегляд',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: _applyCustomUrl,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (widget.current != null && widget.current!.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => Navigator.of(context).pop(''),
                      child: const Text('Прибрати фото'),
                    ),
                  SecondaryButton(
                    label: 'Скасувати',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  PrimaryButton(
                    label: 'Зберегти',
                    onPressed: _selected == null || _selected == widget.current
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.url,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String url;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: UserAvatar(name: name, photoUrl: url, radius: 26),
      ),
    );
  }
}
