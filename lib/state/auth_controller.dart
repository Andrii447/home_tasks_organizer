import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/analytics_service.dart';
import '../data/app_user.dart';
import '../data/repositories/auth_failure.dart';
import '../data/repositories/auth_repository.dart';

enum AuthEvent { signedIn, sessionRestored, signedOut }

/// Стан автентифікації (Provider): поточний користувач, виконання
/// запиту входу/реєстрації та помилка останнього запиту.
class AuthController extends ChangeNotifier {
  AuthController(this._repo, this._analytics) {
    _sub = _repo.authStateChanges().listen(_onUser);
  }

  final AuthRepository _repo;
  final AnalyticsService _analytics;
  late final StreamSubscription<AppUser?> _sub;
  final _events = StreamController<AuthEvent>.broadcast();

  AppUser? _user;
  bool _initialized = false;
  bool _isSubmitting = false;
  String? _error;
  bool _disposed = false;

  AppUser? get user => _user;

  /// Firebase повідомив про стан сеансу (вхід або його відсутність).
  bool get initialized => _initialized;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  /// Одноразові події для повідомлень («Ви увійшли як …» тощо).
  Stream<AuthEvent> get events => _events.stream;

  void _onUser(AppUser? user) {
    final wasInitialized = _initialized;
    final previous = _user;
    _user = user;
    _initialized = true;
    notifyListeners();

    if (!wasInitialized && user != null) {
      _events.add(AuthEvent.sessionRestored);
    } else if (wasInitialized && previous == null && user != null) {
      _events.add(AuthEvent.signedIn);
    } else if (previous != null && user == null) {
      _events.add(AuthEvent.signedOut);
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Виконує запит із блокуванням повторного надсилання.
  Future<bool> _run(Future<void> Function() action) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) =>
      _run(() async {
        await _repo.signIn(email: email, password: password);
        await _analytics.logLogin();
      });

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) => _run(() async {
    await _repo.signUp(name: name, email: email, password: password);
    await _analytics.logSignUp();
  });

  /// FR-03: «користувача не знайдено» вважаємо успіхом, щоб не розкривати,
  /// чи існує акаунт із цією адресою.
  Future<bool> sendPasswordReset(String email) => _run(() async {
    try {
      await _repo.sendPasswordResetEmail(email: email);
    } on AuthFailure catch (e) {
      if (e.code != 'user-not-found') rethrow;
    }
    await _analytics.logEvent('password_reset_requested');
  });

  Future<void> signOut() => _run(_repo.signOut);

  @override
  void dispose() {
    _disposed = true;
    _sub.cancel();
    _events.close();
    super.dispose();
  }
}
