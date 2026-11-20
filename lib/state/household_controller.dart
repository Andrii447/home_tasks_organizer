import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/analytics_service.dart';
import '../core/services/error_reporter.dart';
import '../data/app_user.dart';
import '../data/models.dart';
import '../data/repositories/data_failure.dart';
import '../data/repositories/household_repository.dart';
import 'load_status.dart';

/// Стан домогосподарства поточного користувача (FR-06, FR-07).
/// Дані приходять із Firestore у реальному часі.
class HouseholdController extends ChangeNotifier {
  HouseholdController(this._repo, this._analytics, this._errors);

  final HouseholdRepository _repo;
  final AnalyticsService _analytics;
  final ErrorReporter _errors;

  StreamSubscription<Household?>? _sub;
  AppUser? _user;
  LoadStatus _status = LoadStatus.idle;
  Household? _household;
  bool _isBusy = false;
  String? _error;
  bool _disposed = false;

  LoadStatus get status => _status;
  Household? get household => _household;
  String? get currentUserId => _user?.uid;
  bool get isOwner => _household?.isOwner(_user?.uid) ?? false;
  List<Member> get members => _household?.members ?? const [];

  /// Виконується запит створення / приєднання / зміни (блокує кнопки).
  bool get isBusy => _isBusy;

  /// Помилка останньої дії для показу користувачу.
  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Викликається ChangeNotifierProxyProvider при зміні користувача.
  void bindUser(AppUser? user) {
    final previous = _user;
    _user = user;
    if (user?.uid != previous?.uid) {
      _sub?.cancel();
      _sub = null;
      _household = null;
      _error = null;
      if (user == null) {
        _status = LoadStatus.idle;
        return;
      }
      _status = LoadStatus.loading;
      _sub = _repo
          .watchHouseholdOf(user.uid)
          .listen(
            (household) {
              _household = household;
              _status = LoadStatus.ready;
              _notify();
              _syncMyName();
            },
            onError: (Object e, StackTrace st) {
              _status = LoadStatus.failure;
              _notify();
              _errors.report(e, st, hint: 'household');
            },
          );
    } else if (user != null && user.name != previous?.name) {
      scheduleMicrotask(_syncMyName);
    }
  }

  /// Повторна підписка після помилки завантаження.
  void retry() {
    final user = _user;
    _user = null;
    bindUser(user);
    _notify();
  }

  /// Ім'я в профілі змінилося — оновлюємо його у списку учасників.
  Future<void> _syncMyName() async {
    final h = _household;
    final me = _user;
    if (h == null || me == null || !h.memberIds.contains(me.uid)) return;
    if (h.memberNames[me.uid] == me.name) return;
    try {
      await _repo.updateMemberName(h.id, Member(id: me.uid, name: me.name));
    } catch (e, st) {
      await _errors.report(e, st, hint: 'household');
    }
  }

  Member get _me => Member(id: _user!.uid, name: _user!.name);

  /// Виконує дію з блокуванням повторного запуску та обробкою помилок.
  Future<bool> _run(Future<void> Function() action, String event) async {
    if (_isBusy || _user == null) return false;
    _isBusy = true;
    _error = null;
    _notify();
    try {
      await action();
      await _analytics.logEvent(event);
      return true;
    } on DataFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  Future<bool> create(String name) =>
      _run(() => _repo.create(name: name, owner: _me), 'household_created');

  Future<bool> join(String code) =>
      _run(() => _repo.join(code: code, me: _me), 'household_joined');

  Future<bool> rename(String name) {
    final h = _household;
    if (h == null || !isOwner) return Future.value(false);
    return _run(() => _repo.rename(h.id, name), 'household_renamed');
  }

  Future<bool> removeMember(String memberId) {
    final h = _household;
    if (h == null || !isOwner || memberId == h.ownerId) {
      return Future.value(false);
    }
    return _run(() => _repo.removeMember(h.id, memberId), 'member_removed');
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
