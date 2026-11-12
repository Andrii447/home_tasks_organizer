import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthController>().clearError(),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.sendPasswordReset(_email.text.trim());
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final loading = auth.isSubmitting;
    final error = auth.error;
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
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 20),
                if (error != null) ...[
                  FormMessage(error),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                  label: 'Надіслати лист',
                  onPressed: _submit,
                  loading: loading,
                  expanded: true,
                ),
                const SizedBox(height: 12),
                back,
              ],
            ),
    );
  }
}
