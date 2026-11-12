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
    final tasks = context.read<TasksController>();
    final members = context.read<HouseholdController>().members;
    final created = await showTaskFormDialog(context, members: members);
    if (created != null) await tasks.add(created);
  }

  static Future<void> edit(BuildContext context, HomeTask task) async {
    final tasks = context.read<TasksController>();
    final members = context.read<HouseholdController>().members;
    final updated = await showTaskFormDialog(
      context,
      members: members,
      task: task,
    );
    if (updated != null) await tasks.update(updated);
  }

  /// Повертає true, якщо завдання видалено.
  static Future<bool> delete(BuildContext context, HomeTask task) async {
    final tasks = context.read<TasksController>();
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
    await tasks.delete(task.id);
    return true;
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
