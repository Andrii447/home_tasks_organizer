import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/analytics_service.dart';
import '../core/services/error_reporter.dart';
import '../core/storage/app_preferences.dart';
import '../data/models.dart';
import '../data/repositories/data_failure.dart';
import '../data/repositories/task_repository.dart';
import 'load_status.dart';

typedef PreferencesFactory = AppPreferences Function(String uid);

/// Стан списку завдань (FR-08 – FR-12): завантаження з Firestore у
/// реальному часі, фільтри, створення, редагування та видалення.
class TasksController extends ChangeNotifier {
  TasksController(this._repo, this._prefsFor, this._analytics, this._errors);

  final TaskRepository _repo;
  final PreferencesFactory _prefsFor;
  final AnalyticsService _analytics;
  final ErrorReporter _errors;

  StreamSubscription<List<HomeTask>>? _sub;
  AppPreferences? _prefs;
  String? _uid;
  String? _householdId;
  LoadStatus _status = LoadStatus.idle;
  List<HomeTask> _tasks = [];
  TaskFilters _filters = const TaskFilters();
  bool _isSaving = false;
  String? _saveError;
  bool _disposed = false;

  LoadStatus get status => _status;
  List<HomeTask> get tasks => List.unmodifiable(_tasks);
  TaskFilters get filters => _filters;

  /// Триває створення, редагування чи видалення.
  bool get isSaving => _isSaving;

  /// Помилка останнього збереження.
  String? get saveError => _saveError;

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

  /// Викликається ChangeNotifierProxyProvider2: завдання належать дому,
  /// а фільтри — користувачу.
  void bind(String? uid, String? householdId) {
    if (uid != _uid) {
      _uid = uid;
      _prefs = uid == null ? null : _prefsFor(uid);
      _filters = const TaskFilters();
      if (uid != null) scheduleMicrotask(_loadFilters);
    }
    if (householdId == _householdId) return;
    _householdId = householdId;
    _sub?.cancel();
    _sub = null;
    _tasks = [];
    if (householdId == null) {
      _status = LoadStatus.idle;
      return;
    }
    _status = LoadStatus.loading;
    _sub = _repo
        .watchTasks(householdId)
        .listen(
          (tasks) {
            _tasks = tasks;
            _status = LoadStatus.ready;
            _notify();
          },
          onError: (Object e, StackTrace st) {
            _status = LoadStatus.failure;
            _notify();
            _errors.report(e, st, hint: 'tasks');
          },
        );
  }

  /// Повторна підписка після помилки завантаження.
  void retry() {
    final id = _householdId;
    _householdId = null;
    bind(_uid, id);
    _notify();
  }

  Future<void> _loadFilters() async {
    final prefs = _prefs;
    if (prefs == null) return;
    _filters = await prefs.loadTaskFilters();
    _notify();
  }

  /// Спільна обгортка запису: стан «зберігається» та текст помилки.
  Future<bool> _write(Future<void> Function(String hid) action) async {
    final hid = _householdId;
    if (hid == null || _isSaving) return false;
    _isSaving = true;
    _saveError = null;
    _notify();
    try {
      await action(hid);
      return true;
    } on DataFailure catch (e) {
      _saveError = e.message;
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  void clearSaveError() {
    if (_saveError == null) return;
    _saveError = null;
    _notify();
  }

  /// Створює нове або зберігає змінене завдання.
  Future<bool> save(HomeTask task) => _write((hid) async {
    if (task.isNew) {
      await _repo.addTask(hid, task.copyWith(createdBy: _uid));
      await _analytics.logEvent('task_created', {'status': task.status.name});
    } else {
      await _repo.updateTask(hid, task);
      await _analytics.logEvent('task_updated');
    }
  });

  Future<bool> changeStatus(HomeTask task, TaskStatus status) {
    if (task.status == status) return Future.value(true);
    return _write((hid) async {
      await _repo.updateTask(hid, task.copyWith(status: status));
      await _analytics.logEvent('task_status_changed', {'status': status.name});
    });
  }

  Future<bool> delete(HomeTask task) => _write((hid) async {
    await _repo.deleteTask(hid, task.id);
    await _analytics.logEvent('task_deleted');
  });

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
    _sub?.cancel();
    super.dispose();
  }
}
