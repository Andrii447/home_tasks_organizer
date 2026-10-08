import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
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
  final _name = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _continue() =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final create = _SetupCard(
      title: 'Створити дім',
      subtitle: 'Створіть новий простір для спільних домашніх справ.',
      field: AppTextField(label: 'Назва домогосподарства', controller: _name),
      buttonLabel: 'Створити',
      onPressed: _continue,
    );
    final join = _SetupCard(
      title: 'Приєднатися до дому',
      subtitle: 'Введіть код, який вам надіслав учасник домогосподарства.',
      field: AppTextField(label: 'Код приєднання', controller: _code),
      buttonLabel: 'Приєднатися',
      onPressed: _continue,
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
    required this.title,
    required this.subtitle,
    required this.field,
    required this.buttonLabel,
    required this.onPressed,
  });

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
          field,
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
