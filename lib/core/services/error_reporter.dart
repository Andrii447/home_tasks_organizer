import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Надсилання помилок у Sentry (Firebase Crashlytics не підтримує Web).
///
/// Необроблені помилки Flutter (FlutterError.onError) і Dart
/// (PlatformDispatcher.instance.onError) Sentry перехоплює сам після
/// SentryFlutter.init; цей клас — для помилок, які ми ловимо вручну.
class ErrorReporter {
  const ErrorReporter({required this.enabled});

  final bool enabled;

  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String? hint,
  }) async {
    debugPrint('[$hint] $error');
    if (!enabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: hint == null ? null : (scope) => scope.setTag('area', hint),
    );
  }

  /// Тестова нефатальна помилка для перевірки інтеграції (завдання 2).
  Future<void> sendTestError() async {
    try {
      throw StateError('Тестова помилка ДімПлан (лабораторна №4)');
    } catch (e, st) {
      await report(e, st, hint: 'test');
    }
  }
}
