import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

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

  // Домогосподарства зберігатимуться у Cloud Firestore (наступні лаби),
  // тому тут лише валідація й перехід на головну (AuthGate під цим екраном).
  void _continue(GlobalKey<FormState> form, String event) {
    if (!form.currentState!.validate()) return;
    AppScope.of(context).analytics.logEvent(event);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final create = _SetupCard(
      title: 'Створити дім',
      subtitle: 'Створіть новий простір для спільних домашніх справ.',
      formKey: _createForm,
      field: AppTextField(
        label: 'Назва домогосподарства',
        controller: _name,
        validator: Validators.householdName,
        onSubmitted: (_) => _continue(_createForm, 'household_created'),
      ),
      buttonLabel: 'Створити',
      onPressed: () => _continue(_createForm, 'household_created'),
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
        onSubmitted: (_) => _continue(_joinForm, 'household_joined'),
      ),
      buttonLabel: 'Приєднатися',
      onPressed: () => _continue(_joinForm, 'household_joined'),
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
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final Widget field;
  final String buttonLabel;
  final VoidCallback onPressed;

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
            expanded: true,
          ),
        ],
      ),
    );
  }
}
