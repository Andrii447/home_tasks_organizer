import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../state/auth_controller.dart';
import '../../state/household_controller.dart';

/// FR-06: створення домогосподарства або приєднання за кодом.
class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _createForm = GlobalKey<FormState>();
  final _joinForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<HouseholdController>().clearError(),
    );
  }

  /// Створює дім у Firestore або приєднує до наявного за кодом.
  /// Після успіху MainShell сам покаже головну сторінку.
  Future<void> _continue(
    GlobalKey<FormState> form, {
    required bool join,
  }) async {
    final households = context.read<HouseholdController>();
    if (households.isBusy || !form.currentState!.validate()) return;
    if (join) {
      await households.join(_code.text.trim());
    } else {
      await households.create(_name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final households = context.watch<HouseholdController>();
    final busy = households.isBusy;
    final create = _SetupCard(
      title: 'Створити дім',
      subtitle: 'Створіть новий простір для спільних домашніх справ.',
      formKey: _createForm,
      field: AppTextField(
        label: 'Назва домогосподарства',
        controller: _name,
        validator: Validators.householdName,
        onSubmitted: (_) => _continue(_createForm, join: false),
      ),
      buttonLabel: 'Створити',
      loading: busy,
      onPressed: () => _continue(_createForm, join: false),
    );
    final join = _SetupCard(
      title: 'Приєднатися до дому',
      subtitle: 'Введіть код, який вам надіслав учасник домогосподарства.',
      formKey: _joinForm,
      field: AppTextField(
        label: 'Код приєднання',
        controller: _code,
        hint: 'ДІМ-XXXX-00',
        validator: Validators.inviteCode,
        onSubmitted: (_) => _continue(_joinForm, join: true),
      ),
      buttonLabel: 'Приєднатися',
      loading: busy,
      onPressed: () => _continue(_joinForm, join: true),
    );

    return AuthScaffold(
      maxWidth: 840,
      child: Column(
        children: [
          Text(
            'Ласкаво просимо до ДімПлан',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return Column(
                  children: [create, const SizedBox(height: 20), join],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: create),
                  const SizedBox(width: 20),
                  Expanded(child: join),
                ],
              );
            },
          ),
          if (households.error != null) ...[
            const SizedBox(height: AppSpacing.large),
            FormMessage(households.error!),
          ],
          const SizedBox(height: AppSpacing.large),
          TextButton(
            onPressed: busy
                ? null
                : () => context.read<AuthController>().signOut(),
            child: const Text('Вийти з акаунту'),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.field,
    required this.buttonLabel,
    required this.onPressed,
    required this.loading,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final Widget field;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Form(key: formKey, child: field),
          const SizedBox(height: 16),
          PrimaryButton(
            label: buttonLabel,
            onPressed: onPressed,
            loading: loading,
            expanded: true,
          ),
        ],
      ),
    );
  }
}
