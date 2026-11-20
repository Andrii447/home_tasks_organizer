import '../models.dart';

/// Завдання домогосподарства (підколекція households/{id}/tasks).
abstract interface class TaskRepository {
  /// Список завдань у реальному часі: зміни інших учасників приходять
  /// без перезавантаження.
  Stream<List<HomeTask>> watchTasks(String householdId);

  /// Створює завдання; [HomeTask.createdBy] має бути заповнене.
  Future<void> addTask(String householdId, HomeTask task);

  Future<void> updateTask(String householdId, HomeTask task);

  Future<void> deleteTask(String householdId, String taskId);
}
