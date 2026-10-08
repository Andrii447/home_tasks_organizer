import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock_data.dart';

/// FR-04, FR-05: профіль, зміна пароля, вихід з акаунта.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController(text: MockData.userName);
  final _email = TextEditingController(text: MockData.userEmail);
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() =>
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final avatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: _name,
          builder: (_, value, _) => UserAvatar(
            name: value.text.trim().isEmpty
                ? MockData.userName
                : value.text.trim(),
            radius: 40,
          ),
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Завантажити фото',
          icon: Icons.upload_outlined,
          onPressed: () => _toast('Завантаження фото буде додано пізніше'),
        ),
      ],
    );

    final nameField = AppTextField(
      label: 'Ім\'я',
      labelAbove: true,
      controller: _name,
    );
    final emailField = AppTextField(
      label: 'Електронна пошта',
      labelAbove: true,
      controller: _email,
      enabled: false,
      suffixIcon: const Icon(
        Icons.lock_outline,
        color: AppColors.textSecondary,
      ),
    );
    final saveButton = PrimaryButton(
      label: 'Зберегти зміни',
      onPressed: () => _toast('Зміни збережено'),
    );

    final passwordFields = [
      AppTextField(
        label: 'Поточний пароль',
        labelAbove: true,
        obscure: true,
        controller: _currentPassword,
      ),
      AppTextField(
        label: 'Новий пароль',
        labelAbove: true,
        obscure: true,
        controller: _newPassword,
      ),
      AppTextField(
        label: 'Підтвердити пароль',
        labelAbove: true,
        obscure: true,
        controller: _confirmPassword,
      ),
    ];
    final changePassword = PrimaryButton(
      label: 'Змінити пароль',
      onPressed: () {
        _currentPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();
        _toast('Пароль змінено');
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 40 : AppSpacing.medium,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Мій профіль',
                subtitle: 'Оновлюйте особисті дані та налаштування входу',
              ),
              const SizedBox(height: 24),
              AppCard(
                padding: const EdgeInsets.all(24),
                child: wide
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: avatar),
                            const VerticalDivider(width: 49, thickness: 1),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: nameField),
                                      const SizedBox(width: 16),
                                      Expanded(child: emailField),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  saveButton,
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: avatar),
                          const SizedBox(height: 24),
                          nameField,
                          const SizedBox(height: 16),
                          emailField,
                          const SizedBox(height: 16),
                          saveButton,
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Зміна пароля',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Використовуйте надійний пароль, який не застосовується в інших сервісах',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < passwordFields.length; i++) ...[
                            if (i > 0) const SizedBox(width: 16),
                            Expanded(child: passwordFields[i]),
                          ],
                        ],
                      )
                    else
                      Column(
                        children: [
                          for (var i = 0; i < passwordFields.length; i++) ...[
                            if (i > 0) const SizedBox(height: 16),
                            passwordFields[i],
                          ],
                        ],
                      ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: wide
                          ? Alignment.centerRight
                          : Alignment.center,
                      child: changePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: wide ? Alignment.centerRight : Alignment.center,
                child: SecondaryButton(
                  label: 'Вийти з акаунту',
                  icon: Icons.logout,
                  danger: true,
                  onPressed: _logout,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
