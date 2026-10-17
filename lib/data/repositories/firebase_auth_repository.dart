import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/error_reporter.dart';
import '../app_user.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Реалізація [AuthRepository] на Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {this.reporter});

  final FirebaseAuth _auth;
  final ErrorReporter? reporter;

  static AppUser? _map(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );

  /// Перетворює будь-яку помилку на [AuthFailure]; неочікувані — у Sentry.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } on AuthFailure {
      rethrow;
    } catch (e, st) {
      await reporter?.report(e, st, hint: 'auth');
      throw AuthFailure.fromCode('unknown');
    }
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw AuthFailure.fromCode('no-current-user');
    return user;
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await cred.user?.reload();
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () =>
            _auth.signInWithEmailAndPassword(email: email, password: password),
      );

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) =>
      _guard(() async {
        final user = _requireUser();
        await user.updateProfile(displayName: displayName, photoURL: photoUrl);
        await user.reload();
      });

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    final user = _requireUser();
    final credential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  });

  @override
  Future<void> signOut() => _guard(_auth.signOut);
}
