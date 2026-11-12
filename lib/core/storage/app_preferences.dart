import '../../data/models.dart';
import 'local_store.dart';

/// Налаштування користувача, що зберігаються на пристрої:
/// останні вибрані фільтри списку завдань (FR-12).
class TaskFilters {
  const TaskFilters({this.status, this.assigneeId});

  final TaskStatus? status;
  final String? assigneeId;

  Map<String, Object?> toJson() => {
    'status': status?.name,
    'assigneeId': assigneeId,
  };

  factory TaskFilters.fromJson(Map<String, Object?> json) => TaskFilters(
    status: json['status'] == null
        ? null
        : TaskStatus.fromName(json['status'] as String),
    assigneeId: json['assigneeId'] as String?,
  );
}

class AppPreferences {
  AppPreferences(this._store, this._userId);

  final LocalStore _store;
  final String _userId;

  String get _filtersKey => 'prefs.$_userId.taskFilters';

  Future<TaskFilters> loadTaskFilters() async {
    final json = await _store.readJson(_filtersKey);
    return json is Map
        ? TaskFilters.fromJson(json.cast<String, Object?>())
        : const TaskFilters();
  }

  Future<void> saveTaskFilters(TaskFilters filters) =>
      _store.writeJson(_filtersKey, filters.toJson());
}
