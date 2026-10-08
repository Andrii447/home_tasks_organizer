import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/mock_data.dart';
import '../../../data/models.dart';

typedef TaskCallback = void Function(HomeTask task);

class _Actions extends StatelessWidget {
  const _Actions({required this.task, this.onEdit, this.onDelete});

  final HomeTask task;
  final TaskCallback? onEdit;
  final TaskCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Редагувати',
          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          onPressed: () => onEdit?.call(task),
        ),
        IconButton(
          tooltip: 'Видалити',
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () => onDelete?.call(task),
        ),
      ],
    );
  }
}

class _Assignee extends StatelessWidget {
  const _Assignee(this.id);

  final String? id;

  @override
  Widget build(BuildContext context) {
    final member = MockData.memberById(id);
    if (member == null) {
      return const Text(
        'Не призначено',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(name: member.name),
        const SizedBox(width: 10),
        Flexible(child: Text(member.name, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _DueDate extends StatelessWidget {
  const _DueDate(this.task);

  final HomeTask task;

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate;
    if (due == null) return const Text('—');
    return Text(
      formatShortDate(due),
      style: TextStyle(
        color: task.isOverdue ? AppColors.danger : AppColors.textSecondary,
      ),
    );
  }
}

/// Широка версія: таблиця із заголовком.
class TaskTable extends StatelessWidget {
  const TaskTable({super.key, required this.tasks, this.onEdit, this.onDelete});

  final List<HomeTask> tasks;
  final TaskCallback? onEdit;
  final TaskCallback? onDelete;

  static const _headerStyle = TextStyle(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w600,
    fontSize: 13,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              color: AppColors.sidebar,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text('Завдання', style: _headerStyle),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Виконавець', style: _headerStyle),
                  ),
                  Expanded(flex: 3, child: Text('Строк', style: _headerStyle)),
                  Expanded(flex: 3, child: Text('Статус', style: _headerStyle)),
                  SizedBox(width: 96, child: Text('Дії', style: _headerStyle)),
                ],
              ),
            ),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Завдань за цими фільтрами немає',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            for (final task in tasks) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(flex: 3, child: _Assignee(task.assigneeId)),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DueDate(task),
                          if (task.isOverdue) ...[
                            const SizedBox(height: 4),
                            const OverdueChip(),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: StatusChip(status: task.status),
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      child: _Actions(
                        task: task,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Вузька версія: список карток.
class TaskCardList extends StatelessWidget {
  const TaskCardList({
    super.key,
    required this.tasks,
    this.onEdit,
    this.onDelete,
  });

  final List<HomeTask> tasks;
  final TaskCallback? onEdit;
  final TaskCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Завдань за цими фільтрами немає',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final task in tasks) ...[
          AppCard(
            radius: 14,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    _Actions(task: task, onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      Expanded(child: _Assignee(task.assigneeId)),
                      _DueDate(task),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusChip(status: task.status),
                    if (task.isOverdue) const OverdueChip(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
