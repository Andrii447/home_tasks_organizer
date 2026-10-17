/// Помилка автентифікації зі зрозумілим користувачу повідомленням.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;

  /// Firebase вимагає нещодавнього входу для чутливих дій (зміна пароля).
  bool get requiresRecentLogin => code == 'requires-recent-login';

  /// Переклад кодів FirebaseAuthException у повідомлення українською.
  factory AuthFailure.fromCode(String code) {
    final message = switch (code) {
      'invalid-email' => 'Неправильний формат електронної пошти.',
      'user-disabled' => 'Цей акаунт заблоковано.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' => 'Неправильна електронна пошта або пароль.',
      'email-already-in-use' => 'Акаунт із цією поштою вже існує.',
      'weak-password' => 'Пароль занадто простий.',
      'too-many-requests' =>
        'Забагато спроб. Зачекайте кілька хвилин і спробуйте знову.',
      'network-request-failed' =>
        'Немає з\'єднання з інтернетом. Перевірте мережу.',
      'requires-recent-login' =>
        'З міркувань безпеки увійдіть повторно, щоб змінити пароль.',
      'operation-not-allowed' => 'Цей спосіб входу вимкнено в Firebase.',
      'no-current-user' => 'Сеанс завершився. Увійдіть знову.',
      _ => 'Щось пішло не так. Спробуйте ще раз.',
    };
    return AuthFailure(code, message);
  }

  @override
  String toString() => 'AuthFailure($code): $message';
}
