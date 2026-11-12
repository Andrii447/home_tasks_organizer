import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/auth_controller.dart';
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
  @override
  void initState() {
    super.initState();
    // Помилка з іншого екрана (наприклад, реєстрації) тут не потрібна.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthController>().clearError(),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    if (!_formKey.currentState!.validate()) return;
    // Після успішного входу AuthGate сам покаже головну сторінку.
    await auth.signIn(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    final auth = context.watch<AuthController>();
    final loading = auth.isSubmitting;
    final error = auth.error;
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
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Пароль',
                    controller: _password,
                    enabled: !loading,
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
              onPressed: loading
                  ? null
                  : () => nav.pushNamed(AppRoutes.forgotPassword),
              child: const Text('Забули пароль?'),
            ),
          ),
          if (error != null) ...[
            FormMessage(error),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 8),
          PrimaryButton(
            label: 'Увійти',
            onPressed: _submit,
            loading: loading,
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
