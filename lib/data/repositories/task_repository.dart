import '../../core/storage/local_store.dart';
import '../models.dart';

/// Джерело завдань домогосподарства. Поки що дані зберігаються локально
/// на пристрої; у наступних лабораторних реалізацію замінить Firestore.
abstract interface class TaskRepository {
  Future<List<HomeTask>> loadTasks();
  Future<void> saveTask(HomeTask task);
  Future<void> deleteTask(String id);
  Future<void> replaceAll(List<HomeTask> tasks);
}

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(this._store, this._userId);

  final LocalStore _store;
  final String _userId;

  String get _key => 'tasks.$_userId';

  @override
  Future<List<HomeTask>> loadTasks() async {
    final json = await _store.readJson(_key);
    if (json is! List) return [];
    return [
      for (final item in json)
        HomeTask.fromJson((item as Map).cast<String, Object?>()),
    ];
  }

  @override
  Future<void> replaceAll(List<HomeTask> tasks) =>
      _store.writeJson(_key, [for (final t in tasks) t.toJson()]);

  @override
  Future<void> saveTask(HomeTask task) async {
    final tasks = await loadTasks();
    final i = tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) {
      tasks.add(task);
    } else {
      tasks[i] = task;
    }
    await replaceAll(tasks);
  }

  @override
  Future<void> deleteTask(String id) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == id);
    await replaceAll(tasks);
  }
}
