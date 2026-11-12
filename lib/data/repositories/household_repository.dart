import '../../core/storage/local_store.dart';
import '../models.dart';

abstract interface class HouseholdRepository {
  /// null — користувач ще не створив дім і не приєднався до жодного.
  Future<Household?> load();
  Future<void> save(Household household);
  Future<void> clear();
}

class LocalHouseholdRepository implements HouseholdRepository {
  LocalHouseholdRepository(this._store, this._userId);

  final LocalStore _store;
  final String _userId;

  String get _key => 'household.$_userId';

  @override
  Future<Household?> load() async {
    final json = await _store.readJson(_key);
    return json is Map
        ? Household.fromJson(json.cast<String, Object?>())
        : null;
  }

  @override
  Future<void> save(Household household) =>
      _store.writeJson(_key, household.toJson());

  @override
  Future<void> clear() => _store.remove(_key);
}
