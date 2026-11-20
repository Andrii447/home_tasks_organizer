import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../state/household_controller.dart';
import '../../state/tasks_controller.dart';
import 'task_details_screen.dart';
import 'widgets/task_form_dialog.dart';

/// Дії над завданнями, спільні для головної сторінки й екрана перегляду.
abstract final class TaskActions {
  static Future<void> create(BuildContext context) async {
    final members = context.read<HouseholdController>().members;
    await showTaskFormDialog(context, members: members);
  }

  static Future<void> edit(BuildContext context, HomeTask task) async {
    final members = context.read<HouseholdController>().members;
    await showTaskFormDialog(context, members: members, task: task);
  }

  /// Повертає true, якщо завдання видалено.
  static Future<bool> delete(BuildContext context, HomeTask task) async {
    final tasks = context.read<TasksController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити завдання?'),
        content: Text('Завдання «${task.title}» буде видалено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    final deleted = await tasks.delete(task);
    if (!deleted) {
      messenger.showSnackBar(
        SnackBar(content: Text(tasks.saveError ?? 'Не вдалося видалити')),
      );
    }
    return deleted;
  }

  /// Зміна статусу з повідомленням у разі помилки.
  static Future<void> changeStatus(
    BuildContext context,
    HomeTask task,
    TaskStatus status,
  ) async {
    final tasks = context.read<TasksController>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await tasks.changeStatus(task, status)) {
      messenger.showSnackBar(
        SnackBar(content: Text(tasks.saveError ?? 'Не вдалося змінити статус')),
      );
    }
  }

  static void open(BuildContext context, HomeTask task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.taskDetails),
        builder: (_) => TaskDetailsScreen(taskId: task.id),
      ),
    );
  }
}
