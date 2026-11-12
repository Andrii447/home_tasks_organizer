import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_routes.dart';
import 'core/services/analytics_service.dart';
import 'core/services/error_reporter.dart';
import 'core/storage/app_preferences.dart';
import 'core/storage/local_store.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/household_repository.dart';
import 'data/repositories/task_repository.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/register_screen.dart';
import 'state/auth_controller.dart';
import 'state/household_controller.dart';
import 'state/tasks_controller.dart';

class DimPlanApp extends StatelessWidget {
  const DimPlanApp({
    super.key,
    required this.auth,
    required this.analytics,
    required this.errors,
    required this.store,
    this.navigatorObservers = const [],
  });

  final AuthRepository auth;
  final AnalyticsService analytics;
  final ErrorReporter errors;
  final LocalStore store;

  /// Додаткові спостерігачі (наприклад, SentryNavigatorObserver).
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: auth),
        Provider<AnalyticsService>.value(value: analytics),
        Provider<ErrorReporter>.value(value: errors),
        Provider<LocalStore>.value(value: store),
        ChangeNotifierProvider(create: (_) => AuthController(auth, analytics)),
        // Дані дому та завдань прив'язані до користувача: коли він
        // змінюється, контролери перезавантажують його дані зі сховища.
        ChangeNotifierProxyProvider<AuthController, HouseholdController>(
          create: (_) => HouseholdController(
            (uid) => LocalHouseholdRepository(store, uid),
            analytics,
            errors,
          ),
          update: (_, authState, households) =>
              households!..bindUser(authState.user),
        ),
        ChangeNotifierProxyProvider<AuthController, TasksController>(
          create: (_) => TasksController(
            (uid) => LocalTaskRepository(store, uid),
            (uid) => AppPreferences(store, uid),
            analytics,
            errors,
          ),
          update: (_, authState, tasks) =>
              tasks!..bindUser(authState.user?.uid),
        ),
      ],
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
        },
      ),
    );
  }
}
