import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/navigation/app_routes.dart';
import 'core/services/analytics_service.dart';
import 'core/services/error_reporter.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/household/household_setup_screen.dart';

class DimPlanApp extends StatelessWidget {
  const DimPlanApp({
    super.key,
    required this.auth,
    required this.analytics,
    required this.errors,
    this.navigatorObservers = const [],
  });

  final AuthRepository auth;
  final AnalyticsService analytics;
  final ErrorReporter errors;

  /// Додаткові спостерігачі (наприклад, SentryNavigatorObserver).
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      analytics: analytics,
      errors: errors,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ДімПлан',
        theme: AppTheme.light,
        locale: const Locale('uk'),
        supportedLocales: const [Locale('uk')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorObservers: [
          ...analytics.navigatorObservers,
          ...navigatorObservers,
        ],
        initialRoute: AppRoutes.root,
        routes: {
          AppRoutes.root: (_) => const AuthGate(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
          AppRoutes.householdSetup: (_) => const HouseholdSetupScreen(),
        },
      ),
    );
  }
}
