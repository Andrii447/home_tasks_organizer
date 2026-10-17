/// Локальна валідація полів форм (до запиту у Firebase).
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? required(String? value, {String field = 'Поле'}) =>
      (value == null || value.trim().isEmpty) ? '$field обов\'язкове' : null;

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Вкажіть ім\'я';
    if (v.length < 2) return 'Ім\'я має містити щонайменше 2 символи';
    if (v.length > 40) return 'Ім\'я занадто довге (до 40 символів)';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Вкажіть електронну пошту';
    if (!_email.hasMatch(v)) return 'Неправильний формат пошти';
    return null;
  }

  /// Для входу перевіряємо лише наявність — правила складності
  /// стосуються нового пароля.
  static String? passwordPresent(String? value) =>
      (value == null || value.isEmpty) ? 'Вкажіть пароль' : null;

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Вкажіть пароль';
    if (v.length < 8) return 'Пароль має містити щонайменше 8 символів';
    if (!RegExp(r'[A-Za-zА-Яа-яІіЇїЄєҐґ]').hasMatch(v) ||
        !RegExp(r'\d').hasMatch(v)) {
      return 'Пароль має містити літери та цифри';
    }
    return null;
  }

  static String? Function(String?) confirm(String Function() original) =>
      (value) {
        if (value == null || value.isEmpty) return 'Повторіть пароль';
        if (value != original()) return 'Паролі не збігаються';
        return null;
      };

  static String? householdName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Вкажіть назву домогосподарства';
    if (v.length > 40) return 'Назва занадто довга (до 40 символів)';
    return null;
  }

  /// Формат коду приєднання: «ДІМ-7K4M-92».
  static String? inviteCode(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Вкажіть код приєднання';
    if (!RegExp(r'^ДІМ-[A-Z0-9]{4}-\d{2}$').hasMatch(v)) {
      return 'Код має формат ДІМ-XXXX-00';
    }
    return null;
  }

  static String? httpsUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Вкажіть посилання';
    final uri = Uri.tryParse(v);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Посилання має починатися з https://';
    }
    return null;
  }
}
