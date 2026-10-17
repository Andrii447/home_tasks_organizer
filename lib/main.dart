import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/services/analytics_service.dart';
import 'core/services/error_reporter.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'firebase_options.dart';

/// DSN проєкту Sentry передається під час запуску (файл env.json не в git):
/// flutter run -d chrome --dart-define-from-file=env.json
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Версія збірки для прив'язки помилок до релізу (= version у pubspec.yaml).
const _release = String.fromEnvironment(
  'SENTRY_RELEASE',
  defaultValue: 'dimplan@1.0.0+1',
);

final _errors = ErrorReporter(enabled: _sentryDsn.isNotEmpty);

/// Ініціалізація Firebase і запуск UI. Виконується в тій самій зоні,
/// що й runApp (на Web Sentry обгортає appRunner у власну зону, тож
/// ensureInitialized поза нею дає помилку «Zone mismatch»).
Future<void> _runDimPlan() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final app = DimPlanApp(
    auth: FirebaseAuthRepository(FirebaseAuth.instance, reporter: _errors),
    analytics: FirebaseAnalyticsService(FirebaseAnalytics.instance),
    errors: _errors,
    navigatorObservers: [if (_sentryDsn.isNotEmpty) SentryNavigatorObserver()],
  );
  runApp(_sentryDsn.isEmpty ? app : SentryWidget(child: app));
}

Future<void> main() async {
  if (_sentryDsn.isEmpty) {
    debugPrint('SENTRY_DSN не задано — звіти про помилки вимкнено.');
    await _runDimPlan();
    return;
  }

  // SentryFlutter.init сам встановлює FlutterError.onError та
  // PlatformDispatcher.instance.onError (на Web — runZonedGuarded), тож
  // необроблені помилки Flutter і Dart потрапляють у Sentry автоматично.
  await SentryFlutter.init((options) {
    options.dsn = _sentryDsn;
    options.release = _release;
    options.environment = kReleaseMode ? 'production' : 'development';
    options.sendDefaultPii = false;
    // Трасування навігації та запитів; 1.0 — усі транзакції (для лаби),
    // у продакшені варто зменшити, наприклад до 0.2.
    options.tracesSampleRate = 1.0;
  }, appRunner: _runDimPlan);
}
