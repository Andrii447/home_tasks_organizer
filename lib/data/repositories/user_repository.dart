import '../app_user.dart';

/// Профіль користувача у колекції users (ім'я, email, фото).
abstract interface class UserRepository {
  Future<void> saveProfile(AppUser user);
}
