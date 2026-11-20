import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  planned('Заплановано'),
  inProgress('У процесі'),
  completed('Виконано');

  const TaskStatus(this.label);
  final String label;

  static TaskStatus fromName(String? name) => TaskStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => TaskStatus.planned,
  );
}

class Member {
  const Member({required this.id, required this.name});

  final String id;
  final String name;
}

/// Домогосподарство (FR-06, FR-07): документ households/{id}.
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.memberIds,
    required this.memberNames,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;

  /// Список id учасників — використовується правилами доступу Firestore.
  final List<String> memberIds;

  /// Імена учасників (uid → ім'я) для відображення без читання профілів.
  final Map<String, String> memberNames;

  bool isOwner(String? userId) => userId == ownerId;

  List<Member> get members => [
    for (final id in memberIds)
      Member(id: id, name: memberNames[id] ?? 'Учасник'),
  ];

  Member? memberById(String? id) => id != null && memberIds.contains(id)
      ? Member(id: id, name: memberNames[id] ?? 'Учасник')
      : null;

  factory Household.fromFirestore(String id, Map<String, dynamic> data) =>
      Household(
        id: id,
        name: data['name'] as String? ?? '',
        inviteCode: data['inviteCode'] as String? ?? '',
        ownerId: data['ownerId'] as String? ?? '',
        memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
        memberNames: Map<String, String>.from(
          data['memberNames'] as Map? ?? const {},
        ),
      );
}

/// Домашнє завдання (FR-09 – FR-11): документ
/// households/{householdId}/tasks/{id}.
class HomeTask {
  const HomeTask({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    this.description = '',
    this.assigneeId,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? assigneeId;
  final String? createdBy;
  final DateTime? createdAt;

  /// Ще не збережене у Firestore (id видає база під час створення).
  bool get isNew => id.isEmpty;

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

  HomeTask copyWith({TaskStatus? status, String? createdBy}) => HomeTask(
    id: id,
    title: title,
    description: description,
    dueDate: dueDate,
    status: status ?? this.status,
    assigneeId: assigneeId,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt,
  );

  /// Поля, які користувач може змінювати.
  Map<String, Object?> toFirestore() => {
    'title': title,
    'description': description,
    'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
    'status': status.name,
    'assigneeId': assigneeId,
  };

  factory HomeTask.fromFirestore(String id, Map<String, dynamic> data) =>
      HomeTask(
        id: id,
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
        status: TaskStatus.fromName(data['status'] as String?),
        assigneeId: data['assigneeId'] as String?,
        createdBy: data['createdBy'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
}
