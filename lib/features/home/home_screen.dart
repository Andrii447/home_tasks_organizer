import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import 'widgets/stat_card.dart';
import 'widgets/task_form_dialog.dart';
import 'widgets/task_list.dart';

/// FR-08, FR-09, FR-11, FR-12: головна сторінка з показниками,
/// фільтрами та списком завдань. Дані — захардкоджені, зміни живуть
/// лише в пам'яті екрана.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<HomeTask> _tasks = MockData.tasks();
  TaskStatus? _statusFilter;
  String? _assigneeFilter;

  List<HomeTask> get _visible => [
    for (final t in _tasks)
      if ((_statusFilter == null || t.status == _statusFilter) &&
          (_assigneeFilter == null || t.assigneeId == _assigneeFilter))
        t,
  ];

  int _count(TaskStatus s) => _tasks.where((t) => t.status == s).length;

  Future<void> _addTask() async {
    final created = await showTaskFormDialog(context);
    if (created != null) setState(() => _tasks.add(created));
  }

  Future<void> _editTask(HomeTask task) async {
    final updated = await showTaskFormDialog(context, task: task);
    if (updated == null) return;
    setState(() {
      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i != -1) _tasks[i] = updated;
    });
  }

  Future<void> _deleteTask(HomeTask task) async {
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
    if (ok == true) setState(() => _tasks.removeWhere((t) => t.id == task.id));
  }

  Widget _statusDropdown() => _FilterDropdown<TaskStatus?>(
    label: 'Статус',
    value: _statusFilter,
    items: [
      const DropdownMenuItem(value: null, child: Text('Усі статуси')),
      for (final s in TaskStatus.values)
        DropdownMenuItem(value: s, child: Text(s.label)),
    ],
    onChanged: (v) => setState(() => _statusFilter = v),
  );

  Widget _assigneeDropdown() => _FilterDropdown<String?>(
    label: 'Відповідальний',
    value: _assigneeFilter,
    items: [
      const DropdownMenuItem(value: null, child: Text('Усі учасники')),
      for (final m in MockData.members)
        DropdownMenuItem(value: m.id, child: Text(m.name)),
    ],
    onChanged: (v) => setState(() => _assigneeFilter = v),
  );

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCard(
        label: 'Заплановано',
        value: _count(TaskStatus.planned),
        accent: AppColors.plannedFg,
        accentSoft: AppColors.plannedBg,
      ),
      StatCard(
        label: 'У процесі',
        value: _count(TaskStatus.inProgress),
        accent: AppColors.inProgressFg,
        accentSoft: AppColors.inProgressBg,
      ),
      StatCard(
        label: 'Виконано',
        value: _count(TaskStatus.completed),
        accent: AppColors.completedFg,
        accentSoft: AppColors.completedBg,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final gutter = wide ? 40.0 : AppSpacing.medium;

        final addButton = PrimaryButton(
          label: '+ Додати завдання',
          onPressed: _addTask,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Наші домашні справи',
                subtitle: 'Керуйте спільними завданнями',
                trailing: wide ? addButton : null,
              ),
              const SizedBox(height: 24),
              if (wide)
                Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const SizedBox(width: 20),
                      Expanded(child: stats[i]),
                    ],
                  ],
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final s in stats)
                      SizedBox(
                        width: (constraints.maxWidth - gutter * 2 - 12) / 2,
                        child: s,
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              if (wide)
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: 200, child: _statusDropdown()),
                    SizedBox(width: 200, child: _assigneeDropdown()),
                  ],
                )
              else ...[
                addButton,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statusDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _assigneeDropdown()),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              if (wide)
                TaskTable(
                  tasks: _visible,
                  onEdit: _editTask,
                  onDelete: _deleteTask,
                )
              else
                TaskCardList(
                  tasks: _visible,
                  onEdit: _editTask,
                  onDelete: _deleteTask,
                ),
            ],
          ),
        );
      },
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
