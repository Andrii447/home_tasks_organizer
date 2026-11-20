import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_user.dart';
import 'data_failure.dart';
import 'user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> saveProfile(AppUser user) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
      }, SetOptions(merge: true));
    } catch (e) {
      throw DataFailure.from(e);
    }
  }
}
