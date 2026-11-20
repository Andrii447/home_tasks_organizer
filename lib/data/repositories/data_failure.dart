import 'package:firebase_core/firebase_core.dart';

/// Помилка роботи з хмарними даними зі зрозумілим повідомленням.
class DataFailure implements Exception {
  const DataFailure(this.message, {this.code});

  final String message;
  final String? code;

  factory DataFailure.from(Object error) {
    if (error is DataFailure) return error;
    final code = error is FirebaseException ? error.code : null;
    final message = switch (code) {
      'permission-denied' || 'unauthorized' => 'Недостатньо прав для цієї дії.',
      'unavailable' || 'network-request-failed' || 'retry-limit-exceeded' =>
        'Немає з\'єднання з сервером. Перевірте мережу.',
      'not-found' || 'object-not-found' => 'Дані не знайдено.',
      'quota-exceeded' => 'Перевищено ліміт сховища. Спробуйте пізніше.',
      'canceled' => 'Операцію скасовано.',
      _ => 'Не вдалося зберегти зміни. Спробуйте ще раз.',
    };
    return DataFailure(message, code: code);
  }

  @override
  String toString() => 'DataFailure($code): $message';
}
