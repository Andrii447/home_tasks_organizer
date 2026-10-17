import '../app_user.dart';

/// Контракт автентифікації. UI працює лише з цим інтерфейсом,
/// тож Firebase можна підмінити (наприклад, фейком у тестах).
///
/// Усі методи кидають [AuthFailure] з повідомленням для користувача.
abstract interface class AuthRepository {
  /// Вхід / вихід / відновлення сеансу.
  Stream<AppUser?> authStateChanges();

  /// Як [authStateChanges], а також зміни профілю (ім'я, фото).
  Stream<AppUser?> userChanges();

  AppUser? get currentUser;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Перевіряє поточний пароль (повторна автентифікація) і задає новий.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signOut();
}
