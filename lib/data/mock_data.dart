import 'models.dart';

/// Захардкоджені дані для відображення UI (без бекенду).
abstract final class MockData {
  static const String userName = 'Андрій';
  static const String userEmail = 'andrii@dimplan.ua';
  static const String currentUserId = 'u1';

  static const String householdName = 'Наша квартира';
  static const String inviteCode = 'ДІМ-7K4M-92';

  static const List<Member> members = [
    Member(id: 'u1', name: 'Андрій', isOwner: true),
    Member(id: 'u2', name: 'Марія'),
    Member(id: 'u3', name: 'Олег'),
  ];

  /// Строки задаються відносно сьогодні, щоб позначка «Прострочено»
  /// у демо-даних залишалась актуальною.
  static List<HomeTask> tasks() {
    final today = DateTime.now();
    DateTime inDays(int d) =>
        DateTime(today.year, today.month, today.day).add(Duration(days: d));

    return [
      HomeTask(
        id: 't1',
        title: 'Помити підлогу',
        dueDate: inDays(2),
        status: TaskStatus.inProgress,
        assigneeId: 'u1',
      ),
      HomeTask(
        id: 't2',
        title: 'Купити продукти',
        dueDate: inDays(-2),
        status: TaskStatus.planned,
        assigneeId: 'u2',
      ),
      HomeTask(
        id: 't3',
        title: 'Винести сміття',
        dueDate: inDays(-1),
        status: TaskStatus.completed,
        assigneeId: 'u3',
      ),
      HomeTask(
        id: 't4',
        title: 'Прибрати кухню',
        dueDate: inDays(4),
        status: TaskStatus.planned,
        assigneeId: 'u2',
      ),
      HomeTask(
        id: 't5',
        title: 'Полити квіти',
        dueDate: inDays(1),
        status: TaskStatus.planned,
        assigneeId: 'u1',
      ),
      HomeTask(
        id: 't6',
        title: 'Помити посуд',
        dueDate: inDays(0),
        status: TaskStatus.inProgress,
        assigneeId: 'u3',
      ),
      HomeTask(
        id: 't7',
        title: 'Випрати штори',
        dueDate: inDays(7),
        status: TaskStatus.completed,
        assigneeId: 'u2',
      ),
      HomeTask(
        id: 't8',
        title: 'Пропилососити килим',
        dueDate: inDays(-3),
        status: TaskStatus.completed,
        assigneeId: 'u1',
      ),
      HomeTask(
        id: 't9',
        title: 'Замінити лампочку в коридорі',
        dueDate: inDays(5),
        status: TaskStatus.completed,
        assigneeId: 'u3',
      ),
    ];
  }

  static Member? memberById(String? id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }
}
