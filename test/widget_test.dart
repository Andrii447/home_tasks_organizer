import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_tasks_organizer/app.dart';
import 'package:home_tasks_organizer/core/services/analytics_service.dart';
import 'package:home_tasks_organizer/core/services/error_reporter.dart';
import 'package:home_tasks_organizer/core/storage/local_store.dart';
import 'package:home_tasks_organizer/core/utils/validators.dart';
import 'package:home_tasks_organizer/data/app_user.dart';
import 'package:home_tasks_organizer/data/models.dart';
import 'package:home_tasks_organizer/state/profile_controller.dart';

import 'fake_auth_repository.dart';
import 'fakes.dart';

const andrii = AppUser(
  uid: 'u1',
  email: 'andrii@dimplan.ua',
  displayName: 'Андрій',
);

/// Хмарні репозиторії у пам'яті для одного тесту.
class Cloud {
  final households = FakeHouseholdRepository();
  final tasks = FakeTaskRepository();
  final users = FakeUserRepository();
  final files = FakeFileStorage();
  final store = MemoryStore();

  Cloud() {
    households.tasks = tasks;
  }

  /// Андрій — власник дому з Марією та Олегом і кількома завданнями.
  Household seedHome() {
    final h = households.seed(
      ownerId: 'u1',
      members: {'u1': 'Андрій', 'u2': 'Марія', 'u3': 'Олег'},
    );
    final today = DateTime.now();
    DateTime inDays(int d) =>
        DateTime(today.year, today.month, today.day).add(Duration(days: d));
    tasks.byHousehold[h.id] = [
      HomeTask(
        id: 't1',
        title: 'Помити підлогу',
        dueDate: inDays(2),
        status: TaskStatus.inProgress,
        assigneeId: 'u1',
        createdBy: 'u1',
      ),
      HomeTask(
        id: 't2',
        title: 'Купити продукти',
        dueDate: inDays(-2),
        status: TaskStatus.planned,
        assigneeId: 'u2',
        createdBy: 'u1',
      ),
      HomeTask(
        id: 't3',
        title: 'Винести сміття',
        dueDate: inDays(-1),
        status: TaskStatus.completed,
        assigneeId: 'u3',
        createdBy: 'u2',
      ),
    ];
    return h;
  }
}

Future<Cloud> pumpApp(
  WidgetTester tester, {
  AppUser? signedIn,
  Cloud? cloud,
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final c = cloud ?? Cloud();
  await tester.pumpWidget(
    DimPlanApp(
      auth: FakeAuthRepository(signedIn: signedIn),
      households: c.households,
      tasks: c.tasks,
      users: c.users,
      files: c.files,
      analytics: const NoopAnalyticsService(),
      errors: const ErrorReporter(enabled: false),
      store: c.store,
    ),
  );
  await tester.pumpAndSettle();
  return c;
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

  group('ProfileController.uploadPhoto', () {
    late FakeAuthRepository auth;
    late FakeFileStorage files;
    late FakeUserRepository users;
    late ProfileController profile;

    setUp(() {
      auth = FakeAuthRepository(signedIn: andrii);
      files = FakeFileStorage();
      users = FakeUserRepository();
      profile = ProfileController(
        auth,
        users,
        files,
        const NoopAnalyticsService(),
      );
    });

    test('rejects unsupported type and files over 5 MB', () async {
      expect(
        await profile.uploadPhoto(Uint8List(10), 'image/gif'),
        'Підтримуються лише зображення JPEG і PNG.',
      );
      expect(
        await profile.uploadPhoto(Uint8List(5 * 1024 * 1024 + 1), 'image/png'),
        'Файл завеликий: максимум 5 МБ.',
      );
      expect(files.uploads, isEmpty);
    });

    test('uploads to storage and sets the photo URL', () async {
      expect(await profile.uploadPhoto(Uint8List(100), 'image/png'), isNull);
      expect(files.uploads.keys.single, startsWith('users/u1/avatar/'));
      expect(auth.currentUser!.photoUrl, startsWith('https://storage.example'));
      expect(users.saved['u1']!.photoUrl, auth.currentUser!.photoUrl);
    });

    test('a new photo removes the previous one from storage', () async {
      await profile.uploadPhoto(Uint8List(100), 'image/png');
      await profile.uploadPhoto(Uint8List(100), 'image/jpeg');
      expect(files.uploads.keys.single, 'users/u1/avatar/1.png');
      expect(auth.currentUser!.photoUrl, endsWith('/avatar/1.png'));
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

  testWidgets('create a household, then create a task', (tester) async {
    final cloud = await pumpApp(tester, signedIn: andrii);
    expect(find.text('Ласкаво просимо до ДімПлан'), findsOneWidget);

    await tester.enterText(fields().at(0), 'Наша хата');
    await tester.tap(find.text('Створити'));
    await tester.pumpAndSettle();
    expect(find.text('Наші домашні справи'), findsOneWidget);
    expect(cloud.households.households.values.single.ownerId, 'u1');

    await tester.tap(find.text('+ Додати завдання'));
    await tester.pumpAndSettle();
    await tester.enterText(fields().first, 'Полити квіти');
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();

    expect(find.text('Полити квіти'), findsOneWidget);
    final saved = cloud.tasks.byHousehold.values.single.single;
    expect(saved.title, 'Полити квіти');
    expect(saved.createdBy, 'u1');
  });

  testWidgets('save error keeps the dialog open with a message', (
    tester,
  ) async {
    final cloud = Cloud()..seedHome();
    cloud.tasks.failWrites = true;
    await pumpApp(tester, signedIn: andrii, cloud: cloud);

    await tester.tap(find.text('+ Додати завдання'));
    await tester.pumpAndSettle();
    await tester.enterText(fields().first, 'Полити квіти');
    await tester.tap(find.text('Зберегти'));
    await tester.pumpAndSettle();

    expect(find.text('Нове завдання'), findsOneWidget);
    expect(
      find.text('Немає з\'єднання з сервером. Перевірте мережу.'),
      findsOneWidget,
    );
  });

  testWidgets('wrong invite code shows an error', (tester) async {
    await pumpApp(tester, signedIn: andrii);

    await tester.enterText(fields().at(1), 'ДІМ-AAAA-11');
    await tester.tap(find.text('Приєднатися'));
    await tester.pumpAndSettle();

    expect(find.text('Дім із таким кодом не знайдено.'), findsOneWidget);
  });

  testWidgets('joining by code makes the user a regular member', (
    tester,
  ) async {
    final cloud = Cloud();
    cloud.households.seed(ownerId: 'u2', members: {'u2': 'Марія'});
    await pumpApp(tester, signedIn: andrii, cloud: cloud);

    await tester.enterText(fields().at(1), 'дім-7k4m-92');
    await tester.tap(find.text('Приєднатися'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мій дім').first);
    await tester.pumpAndSettle();

    expect(find.text('Наша квартира'), findsOneWidget);
    expect(find.text('Змінювати назву може лише власник'), findsOneWidget);
    expect(find.byTooltip('Видалити учасника'), findsNothing);
    expect(cloud.households.households.values.single.memberIds, contains('u1'));
  });

  testWidgets('session restored with data from the cloud', (tester) async {
    await pumpApp(tester, signedIn: andrii, cloud: Cloud()..seedHome());

    expect(find.text('Сеанс відновлено: Андрій'), findsOneWidget);
    expect(find.text('Купити продукти'), findsOneWidget);
  });

  testWidgets('task can be opened, completed and deleted', (tester) async {
    final cloud = Cloud();
    final home = cloud.seedHome();
    await pumpApp(tester, signedIn: andrii, cloud: cloud);

    await tester.tap(find.text('Помити підлогу'));
    await tester.pumpAndSettle();
    expect(find.text('Змінити статус'), findsOneWidget);

    // Сегмент «Виконано» на екрані перегляду завдання.
    await tester.tap(find.text('Виконано').last);
    await tester.pumpAndSettle();
    final stored = cloud.tasks.byHousehold[home.id]!;
    expect(stored.firstWhere((t) => t.id == 't1').status, TaskStatus.completed);

    await tester.tap(find.byTooltip('Видалити').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити').last);
    await tester.pumpAndSettle();

    expect(find.text('Змінити статус'), findsNothing);
    expect(find.text('Помити підлогу'), findsNothing);
    expect(stored.any((t) => t.id == 't1'), isFalse);
  });

  testWidgets('status filter is applied and remembered', (tester) async {
    final cloud = Cloud()..seedHome();
    await pumpApp(tester, signedIn: andrii, cloud: cloud);

    await tester.tap(find.text('Усі статуси'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Виконано').last);
    await tester.pumpAndSettle();

    expect(find.text('Винести сміття'), findsOneWidget);
    expect(find.text('Купити продукти'), findsNothing);
    expect(cloud.store.data['prefs.u1.taskFilters'], contains('completed'));
  });

  testWidgets('owner renames household and removes a member', (tester) async {
    final cloud = Cloud();
    final home = cloud.seedHome();
    await pumpApp(tester, signedIn: andrii, cloud: cloud);
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

    final saved = cloud.households.households[home.id]!;
    expect(saved.name, 'Наша хата');
    expect(saved.memberIds, isNot(contains('u2')));
    // FR-07: завдання видаленого учасника залишаються без виконавця.
    final tasks = cloud.tasks.byHousehold[home.id]!;
    expect(tasks.where((t) => t.assigneeId == 'u2'), isEmpty);
  });

  testWidgets('removed member loses access and sees setup again', (
    tester,
  ) async {
    final cloud = Cloud();
    final home = cloud.seedHome();
    const maria = AppUser(
      uid: 'u2',
      email: 'maria@dimplan.ua',
      displayName: 'Марія',
    );
    await pumpApp(tester, signedIn: maria, cloud: cloud);
    expect(find.text('Наші домашні справи'), findsOneWidget);

    await cloud.households.removeMember(home.id, 'u2');
    await tester.pumpAndSettle();

    expect(find.text('Ласкаво просимо до ДімПлан'), findsOneWidget);
  });

  testWidgets('narrow home layout has no overflow', (tester) async {
    await pumpApp(
      tester,
      signedIn: andrii,
      cloud: Cloud()..seedHome(),
      size: const Size(390, 844),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Заплановано'), findsWidgets);
  });

  testWidgets('logout returns to the login screen', (tester) async {
    await pumpApp(tester, signedIn: andrii, cloud: Cloud()..seedHome());

    await tester.tap(find.text('Профіль').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Вийти з акаунту'));
    await tester.tap(find.text('Вийти з акаунту'));
    await tester.pumpAndSettle();

    expect(find.text('Вхід до ДімПлану'), findsOneWidget);
  });
}
