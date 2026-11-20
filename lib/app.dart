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
import 'data/repositories/file_storage_repository.dart';
import 'data/repositories/household_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/user_repository.dart';
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
    required this.households,
    required this.tasks,
    required this.users,
    required this.files,
    required this.analytics,
    required this.errors,
    required this.store,
    this.navigatorObservers = const [],
  });

  final AuthRepository auth;
  final HouseholdRepository households;
  final TaskRepository tasks;
  final UserRepository users;
  final FileStorageRepository files;
  final AnalyticsService analytics;
  final ErrorReporter errors;
  final LocalStore store;

  /// Додаткові спостерігачі (наприклад, SentryNavigatorObserver).
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Репозиторії та сервіси (Dependency Injection через Provider).
        Provider<AuthRepository>.value(value: auth),
        Provider<HouseholdRepository>.value(value: households),
        Provider<TaskRepository>.value(value: tasks),
        Provider<UserRepository>.value(value: users),
        Provider<FileStorageRepository>.value(value: files),
        Provider<AnalyticsService>.value(value: analytics),
        Provider<ErrorReporter>.value(value: errors),
        Provider<LocalStore>.value(value: store),
        // Моделі стану.
        ChangeNotifierProvider(create: (_) => AuthController(auth, analytics)),
        // Дім залежить від користувача: при вході іншого користувача
        // контролер підписується на його дім у Firestore.
        ChangeNotifierProxyProvider<AuthController, HouseholdController>(
          create: (_) => HouseholdController(households, analytics, errors),
          update: (_, authState, home) => home!..bindUser(authState.user),
        ),
        // Завдання належать дому, а фільтри — користувачу.
        ChangeNotifierProxyProvider2<
          AuthController,
          HouseholdController,
          TasksController
        >(
          create: (_) => TasksController(
            tasks,
            (uid) => AppPreferences(store, uid),
            analytics,
            errors,
          ),
          update: (_, authState, home, taskState) =>
              taskState!..bind(authState.user?.uid, home.household?.id),
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
