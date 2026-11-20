import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'data_failure.dart';
import 'task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tasks(String householdId) =>
      _db.collection('households').doc(householdId).collection('tasks');

  @override
  Stream<List<HomeTask>> watchTasks(String householdId) => _tasks(householdId)
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            HomeTask.fromFirestore(doc.id, doc.data()),
        ],
      )
      .handleError((Object e) => throw DataFailure.from(e));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      throw DataFailure.from(e);
    }
  }

  @override
  Future<void> addTask(String householdId, HomeTask task) => _guard(
    () => _tasks(householdId).add({
      ...task.toFirestore(),
      'createdBy': task.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> updateTask(String householdId, HomeTask task) =>
      _guard(() => _tasks(householdId).doc(task.id).update(task.toFirestore()));

  @override
  Future<void> deleteTask(String householdId, String taskId) =>
      _guard(() => _tasks(householdId).doc(taskId).delete());
}
