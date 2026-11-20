import 'dart:async';
import 'dart:typed_data';

import 'package:home_tasks_organizer/data/app_user.dart';
import 'package:home_tasks_organizer/data/models.dart';
import 'package:home_tasks_organizer/data/repositories/data_failure.dart';
import 'package:home_tasks_organizer/data/repositories/file_storage_repository.dart';
import 'package:home_tasks_organizer/data/repositories/household_repository.dart';
import 'package:home_tasks_organizer/data/repositories/task_repository.dart';
import 'package:home_tasks_organizer/data/repositories/user_repository.dart';

/// Імітація Firestore для домогосподарств (у пам'яті, з потоками).
class FakeHouseholdRepository implements HouseholdRepository {
  final households = <String, Household>{};
  final invites = <String, String>{};
  final userHousehold = <String, String>{};
  final _changes = StreamController<void>.broadcast();
  bool failWrites = false;
  var _seq = 0;

  void _emit() => _changes.add(null);

  Household? _visibleTo(String uid) {
    final h = households[userHousehold[uid]];
    // Як правила Firestore: дім бачать лише учасники.
    return h != null && h.memberIds.contains(uid) ? h : null;
  }

  Future<void> _check() async {
    if (failWrites) {
      throw const DataFailure('Немає з\'єднання з сервером. Перевірте мережу.');
    }
  }

  /// Готовий дім для тестів.
  Household seed({
    required String ownerId,
    required Map<String, String> members,
    String name = 'Наша квартира',
    String code = 'ДІМ-7K4M-92',
  }) {
    final h = Household(
      id: 'h${++_seq}',
      name: name,
      inviteCode: code,
      ownerId: ownerId,
      memberIds: members.keys.toList(),
      memberNames: members,
    );
    households[h.id] = h;
    invites[code] = h.id;
    for (final uid in members.keys) {
      userHousehold[uid] = h.id;
    }
    return h;
  }

  @override
  Stream<Household?> watchHouseholdOf(String uid) async* {
    yield _visibleTo(uid);
    yield* _changes.stream.map((_) => _visibleTo(uid));
  }

  @override
  Future<void> create({required String name, required Member owner}) async {
    await _check();
    seed(
      ownerId: owner.id,
      members: {owner.id: owner.name},
      name: name,
      code: 'ДІМ-NEW${_seq + 1}-10',
    );
    _emit();
  }

  @override
  Future<void> join({required String code, required Member me}) async {
    await _check();
    final id = invites[code.toUpperCase()];
    if (id == null) throw const DataFailure('Дім із таким кодом не знайдено.');
    final h = households[id]!;
    households[id] = Household(
      id: h.id,
      name: h.name,
      inviteCode: h.inviteCode,
      ownerId: h.ownerId,
      memberIds: [...h.memberIds, me.id],
      memberNames: {...h.memberNames, me.id: me.name},
    );
    userHousehold[me.id] = id;
    _emit();
  }

  Household _replace(String id, {String? name, String? removeMember}) {
    final h = households[id]!;
    return households[id] = Household(
      id: h.id,
      name: name ?? h.name,
      inviteCode: h.inviteCode,
      ownerId: h.ownerId,
      memberIds: [
        for (final m in h.memberIds)
          if (m != removeMember) m,
      ],
      memberNames: {...h.memberNames}..remove(removeMember),
    );
  }

  @override
  Future<void> rename(String householdId, String name) async {
    await _check();
    _replace(householdId, name: name);
    _emit();
  }

  /// Пов'язаний репозиторій завдань — щоб зняти виконавця, як у Firestore.
  FakeTaskRepository? tasks;

  @override
  Future<void> removeMember(String householdId, String memberId) async {
    await _check();
    _replace(householdId, removeMember: memberId);
    tasks?.unassign(householdId, memberId);
    _emit();
  }

  @override
  Future<void> updateMemberName(String householdId, Member me) async {
    final h = households[householdId]!;
    households[householdId] = Household(
      id: h.id,
      name: h.name,
      inviteCode: h.inviteCode,
      ownerId: h.ownerId,
      memberIds: h.memberIds,
      memberNames: {...h.memberNames, me.id: me.name},
    );
    _emit();
  }
}

/// Імітація підколекції households/{id}/tasks.
class FakeTaskRepository implements TaskRepository {
  final byHousehold = <String, List<HomeTask>>{};
  final _changes = StreamController<void>.broadcast();
  bool failWrites = false;
  var _seq = 0;

  List<HomeTask> _list(String hid) => byHousehold.putIfAbsent(hid, () => []);

  Future<void> _check() async {
    if (failWrites) {
      throw const DataFailure('Немає з\'єднання з сервером. Перевірте мережу.');
    }
  }

  @override
  Stream<List<HomeTask>> watchTasks(String householdId) async* {
    yield List.of(_list(householdId));
    yield* _changes.stream.map((_) => List.of(_list(householdId)));
  }

  @override
  Future<void> addTask(String householdId, HomeTask task) async {
    await _check();
    _list(householdId).add(
      HomeTask(
        id: 'task${++_seq}',
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        status: task.status,
        assigneeId: task.assigneeId,
        createdBy: task.createdBy,
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> updateTask(String householdId, HomeTask task) async {
    await _check();
    final list = _list(householdId);
    list[list.indexWhere((t) => t.id == task.id)] = task;
    _changes.add(null);
  }

  @override
  Future<void> deleteTask(String householdId, String taskId) async {
    await _check();
    _list(householdId).removeWhere((t) => t.id == taskId);
    _changes.add(null);
  }

  void unassign(String householdId, String memberId) {
    final list = _list(householdId);
    for (var i = 0; i < list.length; i++) {
      final t = list[i];
      if (t.assigneeId == memberId) {
        list[i] = HomeTask(
          id: t.id,
          title: t.title,
          description: t.description,
          dueDate: t.dueDate,
          status: t.status,
          createdBy: t.createdBy,
        );
      }
    }
    _changes.add(null);
  }
}

class FakeUserRepository implements UserRepository {
  final saved = <String, AppUser>{};

  @override
  Future<void> saveProfile(AppUser user) async => saved[user.uid] = user;
}

class FakeFileStorage implements FileStorageRepository {
  final uploads = <String, Uint8List>{};
  var _next = 0;

  @override
  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = 'users/$uid/avatar/${_next++}.png';
    uploads[path] = bytes;
    return 'https://storage.example/$path';
  }

  @override
  Future<void> deleteAvatar(String url) async {
    uploads.remove(url.replaceFirst('https://storage.example/', ''));
  }
}
