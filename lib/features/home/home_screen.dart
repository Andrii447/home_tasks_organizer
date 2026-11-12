import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models.dart';
import '../../state/household_controller.dart';
import '../../state/load_status.dart';
import '../../state/tasks_controller.dart';
import 'task_actions.dart';
import 'widgets/stat_card.dart';
import 'widgets/task_list.dart';

/// FR-08, FR-09, FR-11, FR-12: головна сторінка з показниками,
/// фільтрами та списком завдань. Стан — TasksController (Provider).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksController>();
    final household = context.watch<HouseholdController>().household;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final gutter = wide ? 40.0 : AppSpacing.medium;
        final addButton = PrimaryButton(
          label: '+ Додати завдання',
          onPressed: () => TaskActions.create(context),
        );

        Widget list;
        switch (tasks.status) {
          case LoadStatus.idle || LoadStatus.loading:
            list = const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            );
          case LoadStatus.failure:
            list = SliverToBoxAdapter(
              child: Center(
                child: Column(
                  children: [
                    const Text('Не вдалося завантажити завдання'),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Спробувати ще',
                      onPressed: tasks.load,
                    ),
                  ],
                ),
              ),
            );
          case LoadStatus.ready:
            list = wide
                ? TaskTableSliver(
                    tasks: tasks.visibleTasks,
                    memberById: (id) => household?.memberById(id),
                    onOpen: (t) => TaskActions.open(context, t),
                    onEdit: (t) => TaskActions.edit(context, t),
                    onDelete: (t) => TaskActions.delete(context, t),
                  )
                : TaskCardSliverList(
                    tasks: tasks.visibleTasks,
                    memberById: (id) => household?.memberById(id),
                    onOpen: (t) => TaskActions.open(context, t),
                    onEdit: (t) => TaskActions.edit(context, t),
                    onDelete: (t) => TaskActions.delete(context, t),
                  );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 32, gutter, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: 'Наші домашні справи',
                      subtitle: 'Керуйте спільними завданнями',
                      trailing: wide ? addButton : null,
                    ),
                    const SizedBox(height: 24),
                    _Stats(tasks: tasks, wide: wide),
                    const SizedBox(height: 24),
                    _Filters(
                      tasks: tasks,
                      members: household?.members ?? const [],
                      wide: wide,
                      addButton: addButton,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 32),
              sliver: list,
            ),
          ],
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.tasks, required this.wide});

  final TasksController tasks;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCard(
        label: 'Заплановано',
        value: tasks.count(TaskStatus.planned),
        accent: AppColors.plannedFg,
        accentSoft: AppColors.plannedBg,
      ),
      StatCard(
        label: 'У процесі',
        value: tasks.count(TaskStatus.inProgress),
        accent: AppColors.inProgressFg,
        accentSoft: AppColors.inProgressBg,
      ),
      StatCard(
        label: 'Виконано',
        value: tasks.count(TaskStatus.completed),
        accent: AppColors.completedFg,
        accentSoft: AppColors.completedBg,
      ),
    ];
    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            Expanded(child: stats[i]),
          ],
        ],
      );
    }
    // На вузькому екрані — по дві картки в рядку (рис. 9 ЛР2); висота
    // картки визначається вмістом, тому нічого не обрізається.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in stats) SizedBox(width: cardWidth, child: s),
          ],
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.tasks,
    required this.members,
    required this.wide,
    required this.addButton,
  });

  final TasksController tasks;
  final List<Member> members;
  final bool wide;
  final Widget addButton;

  @override
  Widget build(BuildContext context) {
    final status = _FilterDropdown<TaskStatus?>(
      label: 'Статус',
      value: tasks.filters.status,
      items: [
        const DropdownMenuItem(value: null, child: Text('Усі статуси')),
        for (final s in TaskStatus.values)
          DropdownMenuItem(value: s, child: Text(s.label)),
      ],
      onChanged: tasks.setStatusFilter,
    );
    final assigneeValue = members.any((m) => m.id == tasks.filters.assigneeId)
        ? tasks.filters.assigneeId
        : null;
    final assignee = _FilterDropdown<String?>(
      label: 'Відповідальний',
      value: assigneeValue,
      items: [
        const DropdownMenuItem(value: null, child: Text('Усі учасники')),
        for (final m in members)
          DropdownMenuItem(value: m.id, child: Text(m.name)),
      ],
      onChanged: tasks.setAssigneeFilter,
    );

    if (wide) {
      return Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(width: 200, child: status),
          SizedBox(width: 200, child: assignee),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        addButton,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: status),
            const SizedBox(width: 12),
            Expanded(child: assignee),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        DropdownButtonFormField<T>(
          // Значення може прийти зі збережених налаштувань після першої
          // побудови — ключ змушує поле взяти нове initialValue.
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
