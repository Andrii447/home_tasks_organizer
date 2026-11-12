import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models.dart';
import '../../state/household_controller.dart';
import '../../state/tasks_controller.dart';
import 'task_actions.dart';
import 'widgets/task_list.dart';

/// Перегляд завдання (FR-09, FR-11): деталі, зміна статусу,
/// перехід до редагування та видалення.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksController>();
    final household = context.watch<HouseholdController>().household;
    final task = tasks.byId(taskId);
    final textTheme = Theme.of(context).textTheme;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Завдання не знайдено')),
      );
    }

    final due = task.dueDate;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Завдання'),
        actions: [
          IconButton(
            tooltip: 'Редагувати',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => TaskActions.edit(context, task),
          ),
          IconButton(
            tooltip: 'Видалити',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () async {
              final nav = Navigator.of(context);
              if (await TaskActions.delete(context, task)) nav.pop();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        StatusChip(status: task.status),
                        if (task.isOverdue) const OverdueChip(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Field(
                      label: 'Опис',
                      child: Text(
                        task.description.isEmpty
                            ? 'Без опису'
                            : task.description,
                        style: TextStyle(
                          color: task.description.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _Field(
                      label: 'Строк виконання',
                      child: Text(
                        due == null ? 'Не вказано' : formatNumericDate(due),
                        style: TextStyle(
                          fontSize: 16,
                          color: task.isOverdue
                              ? AppColors.danger
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _Field(
                      label: 'Відповідальний',
                      child: TaskAssignee(
                        household?.memberById(task.assigneeId),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Змінити статус',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TaskStatus>(
                      showSelectedIcon: false,
                      segments: [
                        for (final s in TaskStatus.values)
                          ButtonSegment(
                            value: s,
                            // Один рядок: на вузькому екрані текст
                            // зменшується, а не переноситься.
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(s.label, maxLines: 1),
                            ),
                          ),
                      ],
                      selected: {task.status},
                      onSelectionChanged: (s) =>
                          tasks.changeStatus(task, s.first),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
