/// Дані профілю, які зберігає Firebase Authentication.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// Ім'я для відображення: displayName або частина email до «@».
  String get name {
    final n = displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return email.split('@').first;
  }
}
