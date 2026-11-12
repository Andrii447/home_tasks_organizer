import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/analytics_service.dart';
import '../core/services/error_reporter.dart';
import '../core/storage/app_preferences.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../data/repositories/task_repository.dart';
import 'load_status.dart';

typedef TaskRepositoryFactory = TaskRepository Function(String uid);
typedef PreferencesFactory = AppPreferences Function(String uid);

/// Стан списку завдань (FR-08 – FR-12): завантаження, фільтри,
/// створення, редагування, зміна статусу та видалення.
class TasksController extends ChangeNotifier {
  TasksController(this._repoFor, this._prefsFor, this._analytics, this._errors);

  final TaskRepositoryFactory _repoFor;
  final PreferencesFactory _prefsFor;
  final AnalyticsService _analytics;
  final ErrorReporter _errors;

  TaskRepository? _repo;
  AppPreferences? _prefs;
  String? _uid;
  LoadStatus _status = LoadStatus.idle;
  List<HomeTask> _tasks = [];
  TaskFilters _filters = const TaskFilters();
  bool _disposed = false;

  LoadStatus get status => _status;
  List<HomeTask> get tasks => List.unmodifiable(_tasks);
  TaskFilters get filters => _filters;

  /// Завдання з урахуванням вибраних фільтрів.
  List<HomeTask> get visibleTasks => [
    for (final t in _tasks)
      if ((_filters.status == null || t.status == _filters.status) &&
          (_filters.assigneeId == null || t.assigneeId == _filters.assigneeId))
        t,
  ];

  int count(TaskStatus status) =>
      _tasks.where((t) => t.status == status).length;

  HomeTask? byId(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Викликається ChangeNotifierProxyProvider при зміні користувача.
  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _tasks = [];
    _filters = const TaskFilters();
    if (uid == null) {
      _repo = null;
      _prefs = null;
      _status = LoadStatus.idle;
      return;
    }
    _repo = _repoFor(uid);
    _prefs = _prefsFor(uid);
    _status = LoadStatus.loading;
    scheduleMicrotask(load);
  }

  Future<void> load() async {
    final repo = _repo;
    if (repo == null) return;
    _status = LoadStatus.loading;
    _notify();
    try {
      _tasks = await repo.loadTasks();
      _filters = await _prefs!.loadTaskFilters();
      _status = LoadStatus.ready;
    } catch (e, st) {
      _status = LoadStatus.failure;
      await _errors.report(e, st, hint: 'tasks');
    }
    _notify();
  }

  /// Демо-завдання для нового домогосподарства (до інтеграції Firestore).
  Future<void> seedDemo(String me) async {
    _tasks = MockData.tasks(me);
    _status = LoadStatus.ready;
    _notify();
    await _repo?.replaceAll(_tasks);
  }

  Future<void> add(HomeTask task) async {
    _tasks = [..._tasks, task];
    _notify();
    await _repo?.saveTask(task);
    await _analytics.logEvent('task_created', {'status': task.status.name});
  }

  Future<void> update(HomeTask task) async {
    _tasks = [for (final t in _tasks) t.id == task.id ? task : t];
    _notify();
    await _repo?.saveTask(task);
    await _analytics.logEvent('task_updated');
  }

  Future<void> changeStatus(HomeTask task, TaskStatus status) async {
    if (task.status == status) return;
    await update(task.copyWith(status: status));
    await _analytics.logEvent('task_status_changed', {'status': status.name});
  }

  Future<void> delete(String id) async {
    _tasks = [
      for (final t in _tasks)
        if (t.id != id) t,
    ];
    _notify();
    await _repo?.deleteTask(id);
    await _analytics.logEvent('task_deleted');
  }

  /// FR-07: завдання видаленого учасника залишаються без виконавця.
  Future<void> unassignMember(String memberId) async {
    final affected = _tasks.where((t) => t.assigneeId == memberId).toList();
    if (affected.isEmpty) return;
    _tasks = [
      for (final t in _tasks)
        t.assigneeId == memberId
            ? HomeTask(
                id: t.id,
                title: t.title,
                description: t.description,
                dueDate: t.dueDate,
                status: t.status,
              )
            : t,
    ];
    _notify();
    await _repo?.replaceAll(_tasks);
    if (_filters.assigneeId == memberId) await setAssigneeFilter(null);
  }

  Future<void> setStatusFilter(TaskStatus? status) =>
      _setFilters(TaskFilters(status: status, assigneeId: _filters.assigneeId));

  Future<void> setAssigneeFilter(String? assigneeId) =>
      _setFilters(TaskFilters(status: _filters.status, assigneeId: assigneeId));

  Future<void> _setFilters(TaskFilters filters) async {
    _filters = filters;
    _notify();
    await _prefs?.saveTaskFilters(filters);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
