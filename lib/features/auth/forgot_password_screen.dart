import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_failure.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final scope = AppScope.of(context);
    setState(() => _loading = true);
    try {
      await scope.auth.sendPasswordResetEmail(email: _email.text.trim());
      await scope.analytics.logEvent('password_reset_requested');
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      // FR-03: не розкриваємо, чи існує акаунт — «користувача не знайдено»
      // показуємо так само, як успіх.
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        setState(() => _sent = true);
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                Form(
                  key: _formKey,
                  child: AppTextField(
                    label: 'Електронна пошта',
                    controller: _email,
                    enabled: !_loading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  FormMessage(_error!),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                  label: 'Надіслати лист',
                  onPressed: _submit,
                  loading: _loading,
                  expanded: true,
                ),
                const SizedBox(height: 12),
                back,
              ],
            ),
    );
  }
}
