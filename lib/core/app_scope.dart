import 'package:flutter/widgets.dart';

import '../data/repositories/auth_repository.dart';
import 'services/analytics_service.dart';
import 'services/error_reporter.dart';

/// Надає залежності (репозиторій, аналітику, звіти про помилки)
/// усьому дереву віджетів без сторонніх DI-бібліотек.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.analytics,
    required this.errors,
    required super.child,
  });

  final AuthRepository auth;
  final AnalyticsService analytics;
  final ErrorReporter errors;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope не знайдено в дереві віджетів');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth ||
      analytics != oldWidget.analytics ||
      errors != oldWidget.errors;
}
