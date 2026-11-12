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

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  factory Member.fromJson(Map<String, Object?> json) =>
      Member(id: json['id'] as String, name: json['name'] as String);
}

/// Домогосподарство (FR-06, FR-07). Власник може змінювати назву й
/// видаляти учасників.
class Household {
  const Household({
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.members,
  });

  final String name;
  final String inviteCode;
  final String ownerId;
  final List<Member> members;

  bool isOwner(String? userId) => userId == ownerId;

  Member? memberById(String? id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Household copyWith({String? name, List<Member>? members}) => Household(
    name: name ?? this.name,
    inviteCode: inviteCode,
    ownerId: ownerId,
    members: members ?? this.members,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'inviteCode': inviteCode,
    'ownerId': ownerId,
    'members': [for (final m in members) m.toJson()],
  };

  factory Household.fromJson(Map<String, Object?> json) => Household(
    name: json['name'] as String,
    inviteCode: json['inviteCode'] as String,
    ownerId: json['ownerId'] as String,
    members: [
      for (final m in json['members'] as List)
        Member.fromJson((m as Map).cast<String, Object?>()),
    ],
  );
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

  HomeTask copyWith({TaskStatus? status}) => HomeTask(
    id: id,
    title: title,
    description: description,
    dueDate: dueDate,
    status: status ?? this.status,
    assigneeId: assigneeId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'status': status.name,
    'assigneeId': assigneeId,
  };

  factory HomeTask.fromJson(Map<String, Object?> json) => HomeTask(
    id: json['id'] as String,
    title: json['title'] as String,
    description: (json['description'] as String?) ?? '',
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String),
    status: TaskStatus.fromName(json['status'] as String?),
    assigneeId: json['assigneeId'] as String?,
  );
}
