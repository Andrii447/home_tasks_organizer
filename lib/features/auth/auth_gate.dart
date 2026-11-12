import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../state/auth_controller.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Кореневий екран: за станом AuthController показує вхід або головну
/// частину застосунку та повідомляє про вхід, вихід і відновлення сеансу.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthEvent>? _events;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _events ??= context.read<AuthController>().events.listen(_onEvent);
  }

  void _onEvent(AuthEvent event) {
    final name = context.read<AuthController>().user?.name ?? '';
    final message = switch (event) {
      AuthEvent.sessionRestored => 'Сеанс відновлено: $name',
      AuthEvent.signedIn => 'Ви увійшли як $name',
      AuthEvent.signedOut => 'Ви вийшли з акаунту',
    };
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.initialized) return const _Splash();
    return auth.user == null ? const LoginScreen() : const MainShell();
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
