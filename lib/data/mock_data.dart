import 'models.dart';

/// Демонстраційні дані, якими заповнюється нове домогосподарство до
/// інтеграції з Cloud Firestore (дозволено методичкою: «hardcoded»-дані).
abstract final class MockData {
  static const String demoHouseholdName = 'Наша квартира';
  static const String demoInviteCode = 'ДІМ-7K4M-92';

  static const demoMembers = [
    Member(id: 'u2', name: 'Марія'),
    Member(id: 'u3', name: 'Олег'),
  ];

  /// Строки задаються відносно сьогодні, щоб позначка «Прострочено»
  /// у демо-даних залишалась актуальною. `me` — id поточного користувача.
  static List<HomeTask> tasks(String me) {
    final today = DateTime.now();
    DateTime inDays(int d) =>
        DateTime(today.year, today.month, today.day).add(Duration(days: d));

    HomeTask t(String id, String title, int due, TaskStatus s, String who) =>
        HomeTask(
          id: id,
          title: title,
          dueDate: inDays(due),
          status: s,
          assigneeId: who,
        );

    return [
      t('t1', 'Помити підлогу', 2, TaskStatus.inProgress, me),
      t('t2', 'Купити продукти', -2, TaskStatus.planned, 'u2'),
      t('t3', 'Винести сміття', -1, TaskStatus.completed, 'u3'),
      t('t4', 'Прибрати кухню', 4, TaskStatus.planned, 'u2'),
      t('t5', 'Полити квіти', 1, TaskStatus.planned, me),
      t('t6', 'Помити посуд', 0, TaskStatus.inProgress, 'u3'),
      t('t7', 'Випрати штори', 7, TaskStatus.completed, 'u2'),
      t('t8', 'Пропилососити килим', -3, TaskStatus.completed, me),
      t('t9', 'Замінити лампочку в коридорі', 5, TaskStatus.completed, 'u3'),
    ];
  }
}
