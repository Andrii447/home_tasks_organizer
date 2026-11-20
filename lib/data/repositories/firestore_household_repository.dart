import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'data_failure.dart';
import 'household_repository.dart';

class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _households =>
      _db.collection('households');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('invites');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Слухаємо users/{uid}.householdId, а при його зміні перемикаємося
  /// на відповідний документ households/{id}.
  @override
  Stream<Household?> watchHouseholdOf(String uid) {
    late final StreamController<Household?> out;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? homeSub;
    String? currentId;

    void watchHome(String? householdId) {
      if (householdId == currentId && homeSub != null) return;
      currentId = householdId;
      homeSub?.cancel();
      homeSub = null;
      if (householdId == null) {
        out.add(null);
        return;
      }
      homeSub = _households
          .doc(householdId)
          .snapshots()
          .listen(
            (snap) => out.add(
              snap.exists
                  ? Household.fromFirestore(snap.id, snap.data()!)
                  : null,
            ),
            onError: (Object e, StackTrace st) {
              homeSub = null;
              // Користувача видалили з дому — правила більше не дають читати.
              if (e is FirebaseException && e.code == 'permission-denied') {
                out.add(null);
              } else {
                out.addError(DataFailure.from(e), st);
              }
            },
          );
    }

    out = StreamController<Household?>(
      onListen: () {
        userSub = _users
            .doc(uid)
            .snapshots()
            .listen(
              (snap) => watchHome(snap.data()?['householdId'] as String?),
              onError: (Object e, StackTrace st) =>
                  out.addError(DataFailure.from(e), st),
            );
      },
      onCancel: () async {
        await homeSub?.cancel();
        await userSub?.cancel();
      },
    );
    return out.stream;
  }

  static String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final mid = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    return 'ДІМ-$mid-${r.nextInt(90) + 10}';
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw DataFailure.from(e);
    }
  }

  @override
  Future<void> create({required String name, required Member owner}) =>
      _guard(() async {
        // Унікальний код: перевіряємо, що такого ще немає.
        var code = _newInviteCode();
        for (var i = 0; i < 5 && (await _invites.doc(code).get()).exists; i++) {
          code = _newInviteCode();
        }
        final home = _households.doc();
        final batch = _db.batch()
          ..set(home, {
            'name': name,
            'ownerId': owner.id,
            'memberIds': [owner.id],
            'memberNames': {owner.id: owner.name},
            'inviteCode': code,
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(_invites.doc(code), {'householdId': home.id})
          ..set(_users.doc(owner.id), {
            'name': owner.name,
            'householdId': home.id,
          }, SetOptions(merge: true));
        await batch.commit();
      });

  @override
  Future<void> join({required String code, required Member me}) =>
      _guard(() async {
        final invite = await _invites.doc(code.trim().toUpperCase()).get();
        final householdId = invite.data()?['householdId'] as String?;
        if (householdId == null) {
          throw const DataFailure('Дім із таким кодом не знайдено.');
        }
        final batch = _db.batch()
          ..update(_households.doc(householdId), {
            'memberIds': FieldValue.arrayUnion([me.id]),
            FieldPath(['memberNames', me.id]): me.name,
          })
          ..set(_users.doc(me.id), {
            'name': me.name,
            'householdId': householdId,
          }, SetOptions(merge: true));
        await batch.commit();
      });

  @override
  Future<void> rename(String householdId, String name) =>
      _guard(() => _households.doc(householdId).update({'name': name}));

  @override
  Future<void> removeMember(String householdId, String memberId) =>
      _guard(() async {
        final home = _households.doc(householdId);
        final assigned = await home
            .collection('tasks')
            .where('assigneeId', isEqualTo: memberId)
            .get();
        final batch = _db.batch()
          ..update(home, {
            'memberIds': FieldValue.arrayRemove([memberId]),
            FieldPath(['memberNames', memberId]): FieldValue.delete(),
          });
        for (final task in assigned.docs) {
          batch.update(task.reference, {'assigneeId': null});
        }
        await batch.commit();
      });

  @override
  Future<void> updateMemberName(String householdId, Member me) => _guard(
    () => _households.doc(householdId).update({
      FieldPath(['memberNames', me.id]): me.name,
    }),
  );
}
