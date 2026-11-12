import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_tasks_organizer/app.dart';
import 'package:home_tasks_organizer/core/services/analytics_service.dart';
import 'package:home_tasks_organizer/core/services/error_reporter.dart';
import 'package:home_tasks_organizer/core/storage/local_store.dart';
import 'package:home_tasks_organizer/core/utils/validators.dart';
import 'package:home_tasks_organizer/data/app_user.dart';
import 'package:home_tasks_organizer/data/mock_data.dart';
import 'package:home_tasks_organizer/data/models.dart';
import 'package:home_tasks_organizer/data/repositories/household_repository.dart';
import 'package:home_tasks_organizer/data/repositories/task_repository.dart';

import 'fake_auth_repository.dart';

const andrii = AppUser(
  uid: 'u1',
  email: 'andrii@dimplan.ua',
  displayName: 'Андрій',
);

Future<void> pumpApp(
  WidgetTester tester, {
  AppUser? signedIn,
  MemoryStore? store,
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    DimPlanApp(
      auth: FakeAuthRepository(signedIn: signedIn),
      analytics: const NoopAnalyticsService(),
      errors: const ErrorReporter(enabled: false),
      store: store ?? MemoryStore(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Сховище, у якому користувач u1 уже є власником дому з демо-завданнями.
Future<MemoryStore> storeWithHousehold() async {
  final store = MemoryStore();
  await LocalHouseholdRepository(store, 'u1').save(
    const Household(
      name: 'Наша квартира',
      inviteCode: 'ДІМ-7K4M-92',
      ownerId: 'u1',
      members: [
        Member(id: 'u1', name: 'Андрій'),
        ...MockData.demoMembers,
      ],
    ),
  );
  await LocalTaskRepository(store, 'u1').replaceAll(MockData.tasks('u1'));
  return store;
}

Finder fields() => find.byType(TextFormField);

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

  group('Local storage', () {
    test('tasks survive a new repository instance', () async {
      final store = MemoryStore();
      final task = HomeTask(
        id: 'x',
        title: 'Помити вікна',
        dueDate: DateTime(2026, 11, 20),
        status: TaskStatus.inProgress,
        assigneeId: 'u2',
      );
      await LocalTaskRepository(store, 'u1').saveTask(task);

      final loaded = await LocalTaskRepository(store, 'u1').loadTasks();
      expect(loaded.single.title, 'Помити вікна');
      expect(loaded.single.status, TaskStatus.inProgress);
      expect(loaded.single.dueDate, DateTime(2026, 11, 20));
      // Дані різних користувачів не змішуються.
      expect(await LocalTaskRepository(store, 'u2').loadTasks(), isEmpty);
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

    await tester.enterText(fields().at(0), 'andrii@dimplan.ua');
    await tester.enterText(fields().at(1), 'bad');
    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();

    expect(
      find.text('Неправильна електронна пошта або пароль.'),
      findsOneWidget,
    );
  });

  testWidgets('register validates name and password match', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Зареєструватися'));
    await tester.pumpAndSettle();

    await tester.enterText(fields().at(1), 'new@dimplan.ua');
    await tester.enterText(fields().at(2), 'secret123');
    await tester.enterText(fields().at(3), 'secret124');
    await tester.tap(find.text('Зареєструватися').last);
    await tester.pump();

    expect(find.text('Вкажіть ім\'я'), findsOneWidget);
    expect(find.text('Паролі не збігаються'), findsOneWidget);
  });

  testWidgets('first login asks to create a household, then shows tasks', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.enterText(fields().at(0), 'andrii@dimplan.ua');
    await tester.enterText(fields().at(1), 'secret123');
    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();

    expect(find.text('Ласкаво просимо до ДімПлан'), findsOneWidget);

    await tester.enterText(fields().at(0), 'Наша хата');
    await tester.tap(find.text('Створити'));
    await tester.pumpAndSettle();

    expect(find.text('Наші домашні справи'), findsOneWidget);
    expect(find.text('Помити підлогу'), findsOneWidget);
  });

  testWidgets('session restored with data from local storage', (tester) async {
    await pumpApp(tester, signedIn: andrii, store: await storeWithHousehold());

    expect(find.text('Сеанс відновлено: Андрій'), findsOneWidget);
    expect(find.text('Наші домашні справи'), findsOneWidget);
    expect(find.text('Купити продукти'), findsOneWidget);
  });

  testWidgets('task can be opened, completed and deleted', (tester) async {
    final store = await storeWithHousehold();
    await pumpApp(tester, signedIn: andrii, store: store);

    await tester.tap(find.text('Помити підлогу'));
    await tester.pumpAndSettle();
    expect(find.text('Змінити статус'), findsOneWidget);

    // Сегмент «Виконано» на екрані перегляду завдання.
    await tester.tap(find.text('Виконано').last);
    await tester.pumpAndSettle();
    var saved = await LocalTaskRepository(store, 'u1').loadTasks();
    expect(saved.firstWhere((t) => t.id == 't1').status, TaskStatus.completed);

    await tester.tap(find.byTooltip('Видалити').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити').last);
    await tester.pumpAndSettle();

    expect(find.text('Змінити статус'), findsNothing);
    expect(find.text('Помити підлогу'), findsNothing);
    saved = await LocalTaskRepository(store, 'u1').loadTasks();
    expect(saved.any((t) => t.id == 't1'), isFalse);
  });

  testWidgets('status filter is applied and remembered', (tester) async {
    final store = await storeWithHousehold();
    await pumpApp(tester, signedIn: andrii, store: store);

    await tester.tap(find.text('Усі статуси'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Виконано').last);
    await tester.pumpAndSettle();

    expect(find.text('Винести сміття'), findsOneWidget);
    expect(find.text('Купити продукти'), findsNothing);
    expect(store.data['prefs.u1.taskFilters'], contains('completed'));
  });

  testWidgets('owner renames household and removes a member', (tester) async {
    final store = await storeWithHousehold();
    await pumpApp(tester, signedIn: andrii, store: store);
    await tester.tap(find.text('Мій дім').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Змінити назву'));
    await tester.pumpAndSettle();
    await tester.enterText(fields().last, 'Наша хата');
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Наша хата'), findsOneWidget);

    await tester.tap(find.byTooltip('Видалити учасника').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити').last);
    await tester.pumpAndSettle();
    expect(find.text('Марія'), findsNothing);

    final saved = await LocalHouseholdRepository(store, 'u1').load();
    expect(saved!.name, 'Наша хата');
    expect(saved.members.map((m) => m.name), isNot(contains('Марія')));
    // FR-07: завдання видаленого учасника залишаються без виконавця.
    final tasks = await LocalTaskRepository(store, 'u1').loadTasks();
    expect(tasks.where((t) => t.assigneeId == 'u2'), isEmpty);
  });

  testWidgets('logout returns to the login screen', (tester) async {
    await pumpApp(tester, signedIn: andrii, store: await storeWithHousehold());

    await tester.tap(find.text('Профіль').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Вийти з акаунту'));
    await tester.tap(find.text('Вийти з акаунту'));
    await tester.pumpAndSettle();

    expect(find.text('Вхід до ДімПлану'), findsOneWidget);
  });

  testWidgets('narrow home layout has no overflow', (tester) async {
    await pumpApp(
      tester,
      signedIn: andrii,
      store: await storeWithHousehold(),
      size: const Size(390, 844),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Заплановано'), findsWidgets);
  });

  testWidgets('joining by code makes the user a regular member', (
    tester,
  ) async {
    final store = MemoryStore();
    await pumpApp(tester, signedIn: andrii, store: store);

    await tester.enterText(fields().at(1), 'дім-7k4m-92');
    await tester.tap(find.text('Приєднатися'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мій дім').first);
    await tester.pumpAndSettle();

    expect(find.text('Наша квартира'), findsOneWidget);
    expect(find.text('Змінювати назву може лише власник'), findsOneWidget);
    expect(find.byTooltip('Видалити учасника'), findsNothing);
    final saved = await LocalHouseholdRepository(store, 'u1').load();
    expect(saved!.isOwner('u1'), isFalse);
  });
}
