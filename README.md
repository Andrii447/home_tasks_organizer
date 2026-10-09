# ДімПлан (home_tasks_organizer)

Органайзер домашніх справ — спільний список побутових завдань зі строками, виконавцями та статусами.
Варіант 5, цільова платформа **Web** (Flutter).

Лабораторна робота №3 — базова структура застосунку та основні екрани за дизайном із лабораторної №2.
**Без бекенду**: усі дані захардкоджені (`lib/data/mock_data.dart`), без Firebase, REST та сторонніх пакетів.

## Реалізовані екрани

| Екран | Файл | Вимога (ЛР №2) |
|---|---|---|
| Вхід | `lib/features/auth/login_screen.dart` | FR-02 |
| Реєстрація | `lib/features/auth/register_screen.dart` | FR-01 |
| Відновлення пароля | `lib/features/auth/forgot_password_screen.dart` | FR-03 |
| Створення / приєднання до дому | `lib/features/household/household_setup_screen.dart` | FR-06 |
| Головна (статистика, фільтри, список) | `lib/features/home/home_screen.dart` | FR-08, FR-11, FR-12 |
| Форма завдання (створення / редагування) | `lib/features/home/widgets/task_form_dialog.dart` | FR-09, FR-10 |
| Мій дім (учасники) | `lib/features/household/my_household_screen.dart` | FR-07 |
| Профіль, зміна пароля, вихід | `lib/features/profile/profile_screen.dart` | FR-04, FR-05 |

Навігація: вхід → головна; «Зареєструватися» → створення/приєднання до дому → головна; «Вийти з акаунту» → вхід.
Інтерфейс адаптивний: від 840 px — бічна панель і таблиця, на вужчих екранах — нижня навігація та картки.
Створення, редагування, видалення завдань і фільтри працюють лише в пам'яті екрана (без збереження).

## Структура проєкту

```
lib/
├── main.dart, app.dart          # точка входу, MaterialApp, маршрути
├── core/
│   ├── theme/                   # кольори, відступи, ThemeData (Material 3)
│   ├── navigation/              # імена маршрутів
│   ├── utils/                   # форматування дат
│   └── widgets/                 # перевикористовувані віджети (поле, кнопки, картка, чіпи, аватар…)
├── data/                        # моделі та захардкоджені дані
└── features/
    ├── auth/  household/  home/  profile/  shell/
```

## Запуск

```bash
flutter pub get
flutter run -d chrome
flutter test
```

## Використання LLM

**Модель і harness.** Claude Sonnet 5.5 (Anthropic) у застосунку Claude Code (десктопна версія) — агентний harness,
який читає файли проєкту, створює й редагує код, запускає `flutter analyze`, `flutter test` та застосунок у вбудованому браузері.
