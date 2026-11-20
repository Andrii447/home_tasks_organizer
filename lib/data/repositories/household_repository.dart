import '../models.dart';

/// Робота з домогосподарствами (колекції households, invites, users).
abstract interface class HouseholdRepository {
  /// Дім користувача в реальному часі; null — дому немає або доступ
  /// до нього втрачено (користувача видалив власник).
  Stream<Household?> watchHouseholdOf(String uid);

  /// Створює дім, у якому [owner] — власник і єдиний учасник.
  Future<void> create({required String name, required Member owner});

  /// Приєднує [me] до дому за кодом. Кидає [DataFailure], якщо коду немає.
  Future<void> join({required String code, required Member me});

  Future<void> rename(String householdId, String name);

  /// Видаляє учасника; його завдання залишаються без виконавця (FR-07).
  Future<void> removeMember(String householdId, String memberId);

  /// Оновлює ім'я користувача у списку учасників.
  Future<void> updateMemberName(String householdId, Member me);
}
