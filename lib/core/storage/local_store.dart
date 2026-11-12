import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Сховище «ключ — значення» на пристрої. На Web shared_preferences
/// зберігає дані в localStorage браузера.
abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

extension LocalStoreJson on LocalStore {
  Future<Object?> readJson(String key) async {
    final raw = await read(key);
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> writeJson(String key, Object? value) =>
      write(key, jsonEncode(value));
}

class SharedPreferencesStore implements LocalStore {
  SharedPreferencesStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Реалізація в пам'яті — для тестів.
class MemoryStore implements LocalStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}
