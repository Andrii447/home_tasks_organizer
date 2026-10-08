import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final back = TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Назад до входу'),
    );

    return AuthScaffold(
      maxWidth: 440,
      child: _sent
          ? AuthCard(
              title: 'Перевірте пошту',
              // FR-03: інтерфейс не розкриває, чи існує акаунт з цією адресою.
              subtitle: 'Якщо для цієї адреси доступне відновлення, ми надіслали лист з подальшими інструкціями.',
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                back,
              ],
            )
          : AuthCard(
              title: 'Відновлення пароля',
              subtitle: 'Вкажіть електронну пошту, і ми надішлемо посилання для відновлення.',
              children: [
                AppTextField(
                  label: 'Електронна пошта',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => setState(() => _sent = true),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Надіслати лист',
                  onPressed: () => setState(() => _sent = true),
                  expanded: true,
                ),
                const SizedBox(height: 12),
                back,
              ],
            ),
    );
  }
}
