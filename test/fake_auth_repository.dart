import 'dart:async';

import 'package:home_tasks_organizer/data/app_user.dart';
import 'package:home_tasks_organizer/data/repositories/auth_failure.dart';
import 'package:home_tasks_organizer/data/repositories/auth_repository.dart';

/// Імітація Firebase Auth у пам'яті для віджет-тестів.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedIn}) : _user = signedIn {
    _emit();
  }

  final _accounts = <String, String>{'andrii@dimplan.ua': 'secret123'};
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  Duration delay = Duration.zero;

  void _emit() => scheduleMicrotask(() => _controller.add(_user));

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Stream<AppUser?> userChanges() => authStateChanges();

  @override
  AppUser? get currentUser => _user;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(delay);
    if (_accounts[email] != password) {
      throw AuthFailure.fromCode('invalid-credential');
    }
    _user = AppUser(uid: 'u1', email: email, displayName: 'Андрій');
    _emit();
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw AuthFailure.fromCode('email-already-in-use');
    }
    _accounts[email] = password;
    _user = AppUser(uid: 'u2', email: email, displayName: name);
    _emit();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final u = _user!;
    _user = AppUser(
      uid: u.uid,
      email: u.email,
      displayName: displayName ?? u.displayName,
      photoUrl: photoUrl ?? u.photoUrl,
    );
    _emit();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_accounts[_user!.email] != currentPassword) {
      throw AuthFailure.fromCode('invalid-credential');
    }
    _accounts[_user!.email] = newPassword;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _emit();
  }
}
