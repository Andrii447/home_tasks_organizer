import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/household/household_setup_screen.dart';
import 'features/shell/main_shell.dart';

class DimPlanApp extends StatelessWidget {
  const DimPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.householdSetup: (_) => const HouseholdSetupScreen(),
        AppRoutes.home: (_) => const MainShell(),
      },
    );
  }
}
