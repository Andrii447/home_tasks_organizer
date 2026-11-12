import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/analytics_service.dart';
import '../data/app_user.dart';
import '../data/repositories/auth_failure.dart';
import '../data/repositories/auth_repository.dart';

/// Стан екрана профілю (FR-04, FR-05): завантаження даних користувача,
/// збереження імені/фото та зміна пароля.
class ProfileController extends ChangeNotifier {
  ProfileController(this._repo, this._analytics) {
    _user = _repo.currentUser;
    _sub = _repo.userChanges().listen((user) {
      if (user == null) return;
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  final AnalyticsService _analytics;
  late final StreamSubscription<AppUser?> _sub;
  bool _disposed = false;

  AppUser? _user;
  bool _isSavingProfile = false;
  String? _profileError;
  bool _isChangingPassword = false;
  String? _passwordError;
  bool _needsRelogin = false;

  AppUser? get user => _user;
  bool get isSavingProfile => _isSavingProfile;
  String? get profileError => _profileError;
  bool get isChangingPassword => _isChangingPassword;
  String? get passwordError => _passwordError;

  /// Firebase вимагає повторного входу перед зміною пароля.
  bool get needsRelogin => _needsRelogin;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> saveName(String name) async {
    if (_isSavingProfile) return false;
    _isSavingProfile = true;
    _profileError = null;
    _notify();
    try {
      await _repo.updateProfile(displayName: name);
      await _analytics.logEvent('profile_updated');
      return true;
    } on AuthFailure catch (e) {
      _profileError = e.message;
      return false;
    } finally {
      _isSavingProfile = false;
      _notify();
    }
  }

  /// Повертає текст помилки або null у разі успіху.
  Future<String?> changePhoto(String url) async {
    try {
      await _repo.updateProfile(photoUrl: url);
      await _analytics.logEvent('profile_photo_changed');
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_isChangingPassword) return false;
    _isChangingPassword = true;
    _passwordError = null;
    _needsRelogin = false;
    _notify();
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _analytics.logEvent('password_changed');
      return true;
    } on AuthFailure catch (e) {
      _passwordError =
          e.code == 'invalid-credential' || e.code == 'wrong-password'
          ? 'Поточний пароль неправильний.'
          : e.message;
      _needsRelogin = e.requiresRecentLogin;
      return false;
    } finally {
      _isChangingPassword = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub.cancel();
    super.dispose();
  }
}
