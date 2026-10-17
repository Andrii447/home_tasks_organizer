import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_user.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Кореневий екран: слухає стан автентифікації Firebase і показує
/// вхід або головну частину застосунку. Повідомляє про вхід, вихід
/// і відновлення сеансу після перезавантаження сторінки.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AppUser?>? _sub;
  AppUser? _user;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= AppScope.of(context).auth.authStateChanges().listen(_onAuth);
  }

  void _onAuth(AppUser? user) {
    final wasReady = _ready;
    final previous = _user;
    setState(() {
      _user = user;
      _ready = true;
    });

    final String? message;
    if (!wasReady && user != null) {
      message = 'Сеанс відновлено: ${user.name}';
    } else if (wasReady && previous == null && user != null) {
      message = 'Ви увійшли як ${user.name}';
    } else if (previous != null && user == null) {
      message = 'Ви вийшли з акаунту';
    } else {
      message = null;
    }
    if (message != null) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _Splash();
    return _user == null ? const LoginScreen() : const MainShell();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Відновлення сеансу…',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
