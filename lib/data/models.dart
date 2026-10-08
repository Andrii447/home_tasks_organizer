enum TaskStatus {
  planned('Заплановано'),
  inProgress('У процесі'),
  completed('Виконано');

  const TaskStatus(this.label);
  final String label;
}

class Member {
  const Member({required this.id, required this.name, this.isOwner = false});

  final String id;
  final String name;
  final bool isOwner;
}

class HomeTask {
  const HomeTask({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    this.description = '',
    this.assigneeId,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? assigneeId;

  /// Прострочене: строк минув, а завдання ще не виконане.
  bool get isOverdue {
    final due = dueDate;
    if (due == null || status == TaskStatus.completed) return false;
    final now = DateTime.now();
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  HomeTask copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? assigneeId,
  }) {
    return HomeTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
    );
  }
}
