import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'data_failure.dart';
import 'file_storage_repository.dart';

/// Firebase Storage: фото профілю зберігаються як users/{uid}/avatar/{файл}.
class FirebaseFileStorageRepository implements FileStorageRepository {
  FirebaseFileStorageRepository(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ext = contentType == 'image/png' ? 'png' : 'jpg';
    final ref = _storage.ref(
      'users/$uid/avatar/${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    try {
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      throw DataFailure.from(e);
    }
  }

  @override
  Future<void> deleteAvatar(String url) async {
    final Reference ref;
    try {
      // Не наше посилання (готовий аватар, сторонній сайт) — нічого не робимо.
      ref = _storage.refFromURL(url);
    } catch (_) {
      return;
    }
    if (!ref.fullPath.contains('/avatar/')) return;
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      throw DataFailure.from(e);
    }
  }
}
