import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/error_reporter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/file_storage_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../state/auth_controller.dart';
import '../../state/profile_controller.dart';
import 'avatar_picker_dialog.dart';

/// FR-04, FR-05: профіль, зміна пароля, вихід з акаунта.
/// ProfileController створюється лише на час показу цього екрана.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileController(
        context.read<AuthRepository>(),
        context.read<UserRepository>(),
        context.read<FileStorageRepository>(),
        context.read<AnalyticsService>(),
      ),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _profileForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = context.read<ProfileController>().user;
    if (user == null) return;
    _initialized = true;
    _name.text = user.name;
    _email.text = user.email;
  }

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

  Future<void> _saveProfile() async {
    if (!_profileForm.currentState!.validate()) return;
    final ok = await context.read<ProfileController>().saveName(
      _name.text.trim(),
    );
    if (ok && mounted) _toast('Зміни збережено');
  }

  /// FR-05: вибір фото з пристрою та завантаження у Firebase Storage.
  Future<void> _uploadPhoto() async {
    final profile = context.read<ProfileController>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final error = await profile.uploadPhoto(bytes, _contentType(file));
    if (mounted) _toast(error ?? 'Фото завантажено');
  }

  /// Тип файлу: з метаданих або за розширенням.
  static String? _contentType(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) return mime;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  Future<void> _changePhoto() async {
    final profile = context.read<ProfileController>();
    final user = profile.user;
    if (user == null) return;
    final url = await showAvatarPickerDialog(
      context,
      name: user.name,
      current: user.photoUrl,
    );
    if (url == null) return;
    final error = await profile.changePhoto(url);
    if (!mounted) return;
    _toast(error ?? (url.isEmpty ? 'Фото прибрано' : 'Фото оновлено'));
  }

  Future<void> _changePassword() async {
    if (!_passwordForm.currentState!.validate()) return;
    final ok = await context.read<ProfileController>().changePassword(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
    );
    if (!ok || !mounted) return;
    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
    _toast('Пароль змінено');
  }

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    await context.read<AuthController>().signOut();
    nav.popUntil((route) => route.isFirst);
  }

  Future<void> _sendTestError() async {
    await context.read<ErrorReporter>().sendTestError();
    if (mounted) _toast('Тестову помилку надіслано до Sentry');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = context.watch<ProfileController>();
    final user = profile.user;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final avatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 40),
            if (profile.isUploadingPhoto)
              const SizedBox.square(
                dimension: 84,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Завантажити фото',
          icon: Icons.upload_outlined,
          onPressed: profile.isUploadingPhoto ? null : _uploadPhoto,
        ),
        TextButton(
          onPressed: profile.isUploadingPhoto ? null : _changePhoto,
          child: const Text('Обрати готове або за посиланням'),
        ),
      ],
    );

    final nameField = AppTextField(
      label: 'Ім\'я',
      labelAbove: true,
      controller: _name,
      enabled: !profile.isSavingProfile,
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
      loading: profile.isSavingProfile,
    );

    final passwordFields = [
      AppTextField(
        label: 'Поточний пароль',
        labelAbove: true,
        obscure: true,
        controller: _currentPassword,
        enabled: !profile.isChangingPassword,
        autofillHints: const [AutofillHints.password],
        validator: Validators.passwordPresent,
      ),
      AppTextField(
        label: 'Новий пароль',
        labelAbove: true,
        obscure: true,
        controller: _newPassword,
        enabled: !profile.isChangingPassword,
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
        enabled: !profile.isChangingPassword,
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
            if (profile.profileError != null) ...[
              const SizedBox(height: 16),
              FormMessage(profile.profileError!),
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
                      if (profile.passwordError != null) ...[
                        const SizedBox(height: 16),
                        FormMessage(profile.passwordError!),
                      ],
                      if (profile.needsRelogin) ...[
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
                          loading: profile.isChangingPassword,
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
