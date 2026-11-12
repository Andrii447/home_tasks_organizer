import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models.dart';

typedef TaskCallback = void Function(HomeTask task);
typedef MemberLookup = Member? Function(String? id);

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

class TaskAssignee extends StatelessWidget {
  const TaskAssignee(this.member, {super.key});

  final Member? member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    if (m == null) {
      return const Text(
        'Не призначено',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(name: m.name),
        const SizedBox(width: 10),
        Flexible(child: Text(m.name, overflow: TextOverflow.ellipsis)),
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

const _emptyText = Padding(
  padding: EdgeInsets.all(32),
  child: Center(
    child: Text(
      'Завдань за цими фільтрами немає',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  ),
);

/// Широка версія: таблиця завдань як група слайверів усередині
/// CustomScrollView (рядки будуються ліниво через SliverList).
class TaskTableSliver extends StatelessWidget {
  const TaskTableSliver({
    super.key,
    required this.tasks,
    required this.memberById,
    this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final List<HomeTask> tasks;
  final MemberLookup memberById;
  final TaskCallback? onOpen;
  final TaskCallback? onEdit;
  final TaskCallback? onDelete;

  static const _headerStyle = TextStyle(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w600,
    fontSize: 13,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.sidebar,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
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
          ),
          if (tasks.isEmpty)
            const SliverToBoxAdapter(child: _emptyText)
          else
            SliverList.builder(
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final task = tasks[i];
                final last = i == tasks.length - 1;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    InkWell(
                      borderRadius: last
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            )
                          : null,
                      onTap: () => onOpen?.call(task),
                      child: Padding(
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
                            Expanded(
                              flex: 3,
                              child: TaskAssignee(memberById(task.assigneeId)),
                            ),
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
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Вузька версія: список карток (SliverList з роздільниками).
class TaskCardSliverList extends StatelessWidget {
  const TaskCardSliverList({
    super.key,
    required this.tasks,
    required this.memberById,
    this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final List<HomeTask> tasks;
  final MemberLookup memberById;
  final TaskCallback? onOpen;
  final TaskCallback? onEdit;
  final TaskCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SliverToBoxAdapter(child: _emptyText);
    return SliverList.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final task = tasks[i];
        return Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onOpen?.call(task),
            child: Padding(
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
                        Expanded(
                          child: TaskAssignee(memberById(task.assigneeId)),
                        ),
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
          ),
        );
      },
    );
  }
}
