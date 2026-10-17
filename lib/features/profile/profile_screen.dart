import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_user.dart';
import '../../data/repositories/auth_failure.dart';
import 'avatar_picker_dialog.dart';

/// FR-04, FR-05: профіль, зміна пароля, вихід з акаунта (Firebase Auth).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  StreamSubscription<AppUser?>? _sub;
  AppUser? _user;

  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _profileError;
  String? _passwordError;
  bool _needsRelogin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub != null) return;
    final auth = AppScope.of(context).auth;
    _setUser(auth.currentUser, resetName: true);
    _sub = auth.userChanges().listen((u) => _setUser(u));
  }

  void _setUser(AppUser? user, {bool resetName = false}) {
    if (user == null) return;
    final firstLoad = _user == null;
    setState(() => _user = user);
    _email.text = user.email;
    if (resetName || firstLoad) _name.text = user.name;
  }

  @override
  void dispose() {
    _sub?.cancel();
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

  Future<void> _saveProfile() async {
    if (_savingProfile) return;
    setState(() => _profileError = null);
    if (!_profileForm.currentState!.validate()) return;

    final scope = AppScope.of(context);
    setState(() => _savingProfile = true);
    try {
      await scope.auth.updateProfile(displayName: _name.text.trim());
      await scope.analytics.logEvent('profile_updated');
      if (mounted) _toast('Зміни збережено');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _profileError = e.message);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePhoto() async {
    final user = _user;
    if (user == null) return;
    final url = await showAvatarPickerDialog(
      context,
      name: user.name,
      current: user.photoUrl,
    );
    if (url == null || !mounted) return;

    final scope = AppScope.of(context);
    try {
      await scope.auth.updateProfile(photoUrl: url);
      await scope.analytics.logEvent('profile_photo_changed');
      if (mounted) _toast(url.isEmpty ? 'Фото прибрано' : 'Фото оновлено');
    } on AuthFailure catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _changePassword() async {
    if (_savingPassword) return;
    setState(() {
      _passwordError = null;
      _needsRelogin = false;
    });
    if (!_passwordForm.currentState!.validate()) return;

    final scope = AppScope.of(context);
    setState(() => _savingPassword = true);
    try {
      await scope.auth.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      await scope.analytics.logEvent('password_changed');
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) _toast('Пароль змінено');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordError =
            e.code == 'invalid-credential' || e.code == 'wrong-password'
            ? 'Поточний пароль неправильний.'
            : e.message;
        _needsRelogin = e.requiresRecentLogin;
      });
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _logout() async {
    final scope = AppScope.of(context);
    final nav = Navigator.of(context);
    try {
      await scope.auth.signOut();
      nav.popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _sendTestError() async {
    await AppScope.of(context).errors.sendTestError();
    if (mounted) _toast('Тестову помилку надіслано до Sentry');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = _user;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final avatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 40),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Змінити фото',
          icon: Icons.image_outlined,
          onPressed: _changePhoto,
        ),
      ],
    );

    final nameField = AppTextField(
      label: 'Ім\'я',
      labelAbove: true,
      controller: _name,
      enabled: !_savingProfile,
      validator: Validators.name,
      onSubmitted: (_) => _saveProfile(),
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
      onPressed: _saveProfile,
      loading: _savingProfile,
    );

    final passwordFields = [
      AppTextField(
        label: 'Поточний пароль',
        labelAbove: true,
        obscure: true,
        controller: _currentPassword,
        enabled: !_savingPassword,
        autofillHints: const [AutofillHints.password],
        validator: Validators.passwordPresent,
      ),
      AppTextField(
        label: 'Новий пароль',
        labelAbove: true,
        obscure: true,
        controller: _newPassword,
        enabled: !_savingPassword,
        autofillHints: const [AutofillHints.newPassword],
        validator: (v) {
          final base = Validators.newPassword(v);
          if (base != null) return base;
          return v == _currentPassword.text
              ? 'Новий пароль має відрізнятися від поточного'
              : null;
        },
      ),
      AppTextField(
        label: 'Підтвердити пароль',
        labelAbove: true,
        obscure: true,
        controller: _confirmPassword,
        enabled: !_savingPassword,
        validator: Validators.confirm(() => _newPassword.text),
        onSubmitted: (_) => _changePassword(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;

        final profileFields = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: 16),
                  Expanded(child: emailField),
                ],
              )
            else ...[
              nameField,
              const SizedBox(height: 16),
              emailField,
            ],
            if (_profileError != null) ...[
              const SizedBox(height: 16),
              FormMessage(_profileError!),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: wide ? Alignment.centerRight : Alignment.center,
              child: saveButton,
            ),
          ],
        );

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
                child: Form(
                  key: _profileForm,
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(child: avatar),
                              const VerticalDivider(width: 49, thickness: 1),
                              Expanded(child: profileFields),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: avatar),
                            const SizedBox(height: 24),
                            profileFields,
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _passwordForm,
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
                      if (_passwordError != null) ...[
                        const SizedBox(height: 16),
                        FormMessage(_passwordError!),
                      ],
                      if (_needsRelogin) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.login),
                          label: const Text('Вийти й увійти знову'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: wide
                            ? Alignment.centerRight
                            : Alignment.center,
                        child: PrimaryButton(
                          label: 'Змінити пароль',
                          onPressed: _changePassword,
                          loading: _savingPassword,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    TextButton.icon(
                      onPressed: _sendTestError,
                      icon: const Icon(Icons.bug_report_outlined, size: 18),
                      label: const Text('Діагностика: тестова помилка'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                    SecondaryButton(
                      label: 'Вийти з акаунту',
                      icon: Icons.logout,
                      danger: true,
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
