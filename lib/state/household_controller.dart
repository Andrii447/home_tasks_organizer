import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/services/analytics_service.dart';
import '../core/services/error_reporter.dart';
import '../data/app_user.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../data/repositories/household_repository.dart';
import 'load_status.dart';

typedef HouseholdRepositoryFactory = HouseholdRepository Function(String uid);

/// Стан домогосподарства поточного користувача (FR-06, FR-07).
class HouseholdController extends ChangeNotifier {
  HouseholdController(this._repoFor, this._analytics, this._errors);

  final HouseholdRepositoryFactory _repoFor;
  final AnalyticsService _analytics;
  final ErrorReporter _errors;

  HouseholdRepository? _repo;
  AppUser? _user;
  LoadStatus _status = LoadStatus.idle;
  Household? _household;
  bool _disposed = false;

  LoadStatus get status => _status;
  Household? get household => _household;
  String? get currentUserId => _user?.uid;
  bool get isOwner => _household?.isOwner(_user?.uid) ?? false;
  List<Member> get members => _household?.members ?? const [];

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Викликається ChangeNotifierProxyProvider при зміні користувача.
  void bindUser(AppUser? user) {
    final previousUid = _user?.uid;
    _user = user;
    if (user == null) {
      _repo = null;
      _household = null;
      _status = LoadStatus.idle;
      return;
    }
    if (user.uid != previousUid) {
      _repo = _repoFor(user.uid);
      _household = null;
      _status = LoadStatus.loading;
      scheduleMicrotask(load);
    } else {
      scheduleMicrotask(_syncMyName);
    }
  }

  Future<void> load() async {
    final repo = _repo;
    if (repo == null) return;
    _status = LoadStatus.loading;
    _notify();
    try {
      _household = await repo.load();
      _status = LoadStatus.ready;
      await _syncMyName();
    } catch (e, st) {
      _status = LoadStatus.failure;
      await _errors.report(e, st, hint: 'household');
    }
    _notify();
  }

  /// Ім'я в профілі могло змінитися — оновлюємо його у списку учасників.
  Future<void> _syncMyName() async {
    final h = _household;
    final me = _user;
    if (h == null || me == null) return;
    final mine = h.memberById(me.uid);
    if (mine == null || mine.name == me.name) return;
    await _save(
      h.copyWith(
        members: [
          for (final m in h.members)
            m.id == me.uid ? Member(id: me.uid, name: me.name) : m,
        ],
      ),
    );
  }

  Future<void> _save(Household household) async {
    _household = household;
    _notify();
    await _repo?.save(household);
  }

  Member get _me => Member(id: _user!.uid, name: _user!.name);

  static String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final mid = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    return 'ДІМ-$mid-${r.nextInt(90) + 10}';
  }

  /// Створення дому: користувач стає власником. Поки немає бекенду,
  /// до дому додаються демо-учасники.
  Future<void> create(String name) async {
    await _save(
      Household(
        name: name,
        inviteCode: _newInviteCode(),
        ownerId: _user!.uid,
        members: [_me, ...MockData.demoMembers],
      ),
    );
    await _analytics.logEvent('household_created');
  }

  /// Приєднання за кодом — заглушка до Cloud Firestore: код лише
  /// перевіряється формою, а користувач потрапляє в демо-дім.
  Future<void> join(String code) async {
    await _save(
      Household(
        name: MockData.demoHouseholdName,
        inviteCode: code.toUpperCase(),
        ownerId: MockData.demoMembers.first.id,
        members: [...MockData.demoMembers, _me],
      ),
    );
    await _analytics.logEvent('household_joined');
  }

  Future<void> rename(String name) async {
    final h = _household;
    if (h == null || !isOwner) return;
    await _save(h.copyWith(name: name));
  }

  Future<void> removeMember(String memberId) async {
    final h = _household;
    if (h == null || !isOwner || memberId == h.ownerId) return;
    await _save(
      h.copyWith(
        members: [
          for (final m in h.members)
            if (m.id != memberId) m,
        ],
      ),
    );
    await _analytics.logEvent('member_removed');
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
