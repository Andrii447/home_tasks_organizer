import 'dart:typed_data';

/// Хмарне файлове сховище.
abstract interface class FileStorageRepository {
  /// Завантажує фото профілю й повертає HTTPS-посилання на нього.
  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  });

  /// Видаляє попереднє фото профілю, якщо воно лежить у цьому сховищі.
  /// Посилання на сторонні сайти та готові аватари ігноруються.
  Future<void> deleteAvatar(String url);
}
