import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/widgets/widgets.dart';
import 'auth_footer_link.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Без бізнес-логіки: після «реєстрації» — сторінка вибору домогосподарства (FR-01).
  void _submit() =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.householdSetup);

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AuthCard(
        title: 'Створіть акаунт',
        subtitle: 'Збережіть свої плани та працюйте з ними в одному місці.',
        children: [
          AppTextField(
            label: 'Ім\'я',
            controller: _name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Електронна пошта',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Пароль',
            controller: _password,
            obscure: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Підтвердження пароля',
            controller: _confirm,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Зареєструватися',
            onPressed: _submit,
            expanded: true,
          ),
          const SizedBox(height: 16),
          AuthFooterLink(
            text: 'Уже маєте акаунт?',
            action: 'Увійти',
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}
