import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_failure.dart';
import 'auth_footer_link.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final scope = AppScope.of(context);
    setState(() => _loading = true);
    try {
      await scope.auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      await scope.analytics.logLogin();
      // Після успішного входу AuthGate сам покаже головну сторінку.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return AuthScaffold(
      child: AuthCard(
        title: 'Вхід до ДімПлану',
        subtitle: 'Увійдіть, щоб продовжити планування вашого дому.',
        children: [
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Email',
                    controller: _email,
                    enabled: !_loading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Пароль',
                    controller: _password,
                    enabled: !_loading,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.passwordPresent,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () => nav.pushNamed(AppRoutes.forgotPassword),
              child: const Text('Забули пароль?'),
            ),
          ),
          if (_error != null) ...[
            FormMessage(_error!),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 8),
          PrimaryButton(
            label: 'Увійти',
            onPressed: _submit,
            loading: _loading,
            expanded: true,
          ),
          const SizedBox(height: 16),
          AuthFooterLink(
            text: 'Ще не маєте акаунта?',
            action: 'Зареєструватися',
            onPressed: () => nav.pushNamed(AppRoutes.register),
          ),
        ],
      ),
    );
  }
}
