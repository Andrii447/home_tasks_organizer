import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_tasks_organizer/app.dart';
import 'package:home_tasks_organizer/core/services/analytics_service.dart';
import 'package:home_tasks_organizer/core/services/error_reporter.dart';
import 'package:home_tasks_organizer/core/utils/validators.dart';
import 'package:home_tasks_organizer/data/app_user.dart';

import 'fake_auth_repository.dart';

Future<FakeAuthRepository> pumpApp(
  WidgetTester tester, {
  AppUser? signedIn,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final auth = FakeAuthRepository(signedIn: signedIn);
  await tester.pumpWidget(
    DimPlanApp(
      auth: auth,
      analytics: const NoopAnalyticsService(),
      errors: const ErrorReporter(enabled: false),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('andrii@'), isNotNull);
      expect(Validators.email('andrii@dimplan.ua'), isNull);
    });

    test('new password needs 8+ chars with letters and digits', () {
      expect(Validators.newPassword('short1'), isNotNull);
      expect(Validators.newPassword('onlyletters'), isNotNull);
      expect(Validators.newPassword('secret123'), isNull);
    });

    test('invite code format', () {
      expect(Validators.inviteCode('ДІМ-7K4M-92'), isNull);
      expect(Validators.inviteCode('abc'), isNotNull);
    });
  });

  testWidgets('empty login form shows validation errors', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Увійти'));
    await tester.pump();

    expect(find.text('Вкажіть електронну пошту'), findsOneWidget);
    expect(find.text('Вкажіть пароль'), findsOneWidget);
  });

  testWidgets('wrong password shows a readable error', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'andrii@dimplan.ua',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'bad');
    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();

    expect(
      find.text('Неправильна електронна пошта або пароль.'),
      findsOneWidget,
    );
  });

  testWidgets('successful login opens home, logout returns', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'andrii@dimplan.ua',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();

    expect(find.text('Наші домашні справи'), findsOneWidget);
    expect(find.text('Ви увійшли як Андрій'), findsOneWidget);

    await tester.tap(find.text('Профіль').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Вийти з акаунту'));
    await tester.tap(find.text('Вийти з акаунту'));
    await tester.pumpAndSettle();

    expect(find.text('Вхід до ДімПлану'), findsOneWidget);
  });

  testWidgets('existing session is restored on start', (tester) async {
    await pumpApp(
      tester,
      signedIn: const AppUser(
        uid: 'u1',
        email: 'andrii@dimplan.ua',
        displayName: 'Андрій',
      ),
    );

    expect(find.text('Наші домашні справи'), findsOneWidget);
    expect(find.text('Сеанс відновлено: Андрій'), findsOneWidget);
  });

  testWidgets('register validates name and password match', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Зареєструватися'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'new@dimplan.ua');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.enterText(fields.at(3), 'secret124');
    await tester.tap(find.text('Зареєструватися').last);
    await tester.pump();

    expect(find.text('Вкажіть ім\'я'), findsOneWidget);
    expect(find.text('Паролі не збігаються'), findsOneWidget);
  });
}
