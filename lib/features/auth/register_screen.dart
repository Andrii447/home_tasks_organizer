import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/auth_controller.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthController>().clearError(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    if (!_formKey.currentState!.validate()) return;
    final nav = Navigator.of(context);
    final ok = await auth.signUp(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
    // FR-01: новий користувач ще не має дому, тому під цим маршрутом
    // AuthGate вже показує створення або приєднання до домогосподарства.
    if (ok && mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final loading = auth.isSubmitting;
    final error = auth.error;
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
                    enabled: !loading,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.name,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Електронна пошта',
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
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.newPassword,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Підтвердження пароля',
                    controller: _confirm,
                    enabled: !loading,
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
          if (error != null) ...[
            FormMessage(error),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: 'Зареєструватися',
            onPressed: _submit,
            loading: loading,
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
