import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/widgets/widgets.dart';
import 'auth_footer_link.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Без бізнес-логіки: «Увійти» одразу відкриває головну сторінку.
  void _submit() => Navigator.of(context).pushReplacementNamed(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return AuthScaffold(
      child: AuthCard(
        title: 'Вхід до ДімПлану',
        subtitle: 'Увійдіть, щоб продовжити планування вашого дому.',
        children: [
          AppTextField(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Пароль',
            controller: _password,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => nav.pushNamed(AppRoutes.forgotPassword),
              child: const Text('Забули пароль?'),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Увійти', onPressed: _submit, expanded: true),
          const SizedBox(height: 16),
          AuthFooterLink(
            text: 'Ще не маєте акаунта?',
            action: 'Зареєструватися',
            onPressed: () => nav.pushReplacementNamed(AppRoutes.register),
          ),
        ],
      ),
    );
  }
}
