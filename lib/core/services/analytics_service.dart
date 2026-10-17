import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Події аналітики застосунку.
abstract interface class AnalyticsService {
  /// Відстеження переходів між маршрутами Navigator.
  List<NavigatorObserver> get navigatorObservers;

  Future<void> logScreen(String screenName);
  Future<void> logLogin();
  Future<void> logSignUp();
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  late final List<NavigatorObserver> navigatorObservers = [
    FirebaseAnalyticsObserver(analytics: _analytics),
  ];

  @override
  Future<void> logScreen(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  @override
  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'password');

  @override
  Future<void> logSignUp() => _analytics.logSignUp(signUpMethod: 'password');

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) =>
      _analytics.logEvent(name: name, parameters: parameters);
}

/// Порожня реалізація для тестів і запуску без Firebase.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  List<NavigatorObserver> get navigatorObservers => const [];

  @override
  Future<void> logScreen(String screenName) async {}

  @override
  Future<void> logLogin() async {}

  @override
  Future<void> logSignUp() async {}

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {}
}
