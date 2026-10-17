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

/// DSN проєкту Sentry передається під час запуску:
/// flutter run -d chrome --dart-define=SENTRY_DSN=https://...
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final errors = ErrorReporter(enabled: _sentryDsn.isNotEmpty);
  final app = DimPlanApp(
    auth: FirebaseAuthRepository(FirebaseAuth.instance, reporter: errors),
    analytics: FirebaseAnalyticsService(FirebaseAnalytics.instance),
    errors: errors,
    navigatorObservers: [if (_sentryDsn.isNotEmpty) SentryNavigatorObserver()],
  );

  if (_sentryDsn.isEmpty) {
    debugPrint('SENTRY_DSN не задано — звіти про помилки вимкнено.');
    runApp(app);
    return;
  }

  // SentryFlutter.init сам встановлює FlutterError.onError та
  // PlatformDispatcher.instance.onError, тож необроблені помилки Flutter
  // і Dart потрапляють у Sentry автоматично.
  await SentryFlutter.init((options) {
    options.dsn = _sentryDsn;
    options.environment = kReleaseMode ? 'production' : 'development';
    options.sendDefaultPii = false;
  }, appRunner: () => runApp(SentryWidget(child: app)));
}
