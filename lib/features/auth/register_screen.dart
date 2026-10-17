import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_failure.dart';
import 'auth_footer_link.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Ключ створюється один раз у State, а не в build(): інакше форма
  // втрачала б стан (введені значення та помилки) при кожній перебудові.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final scope = AppScope.of(context);
    final nav = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await scope.auth.signUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      await scope.analytics.logSignUp();
      // FR-01: після реєстрації — створення або приєднання до дому.
      nav.pushReplacementNamed(AppRoutes.householdSetup);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AuthCard(
        title: 'Створіть акаунт',
        subtitle: 'Збережіть свої плани та працюйте з ними в одному місці.',
        children: [
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Ім\'я',
                    controller: _name,
                    enabled: !_loading,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.name,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Електронна пошта',
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
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.newPassword,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Підтвердження пароля',
                    controller: _confirm,
                    enabled: !_loading,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    validator: Validators.confirm(() => _password.text),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            FormMessage(_error!),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: 'Зареєструватися',
            onPressed: _submit,
            loading: _loading,
            expanded: true,
          ),
          const SizedBox(height: 16),
          AuthFooterLink(
            text: 'Уже маєте акаунт?',
            action: 'Увійти',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
