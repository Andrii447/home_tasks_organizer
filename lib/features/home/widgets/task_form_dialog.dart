import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/mock_data.dart';
import '../../../data/models.dart';

/// Діалог створення/редагування завдання (FR-09, FR-10, FR-11).
/// Повертає заповнене завдання або `null`, якщо користувач скасував.
Future<HomeTask?> showTaskFormDialog(BuildContext context, {HomeTask? task}) {
  return showDialog<HomeTask>(
    context: context,
    builder: (_) => _TaskFormDialog(task: task),
  );
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({this.task});

  final HomeTask? task;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  late final _title = TextEditingController(text: widget.task?.title);
  late final _description = TextEditingController(
    text: widget.task?.description,
  );
  late DateTime? _dueDate = widget.task?.dueDate;
  late String? _assigneeId = widget.task?.assigneeId;
  late TaskStatus _status = widget.task?.status ?? TaskStatus.planned;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.task != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final title = _title.text.trim();
    Navigator.of(context).pop(
      HomeTask(
        id: widget.task?.id ?? 'new_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        description: _description.text.trim(),
        dueDate: _dueDate,
        status: _status,
        assigneeId: _assigneeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final dateField = _LabeledField(
      label: 'Строк виконання',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: _pickDate,
        child: InputDecorator(
          decoration: InputDecoration(
            suffixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.textSecondary,
            ),
            hintText: 'Оберіть дату',
          ),
          child: Text(
            _dueDate == null ? 'Оберіть дату' : formatNumericDate(_dueDate!),
            style: TextStyle(
              color: _dueDate == null
                  ? const Color(0xFF8C938D)
                  : AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );

    final assigneeField = _LabeledField(
      label: 'Відповідальний',
      child: DropdownButtonFormField<String?>(
        initialValue: _assigneeId,
        isExpanded: true,
        items: [
          const DropdownMenuItem(value: null, child: Text('Не призначено')),
          for (final m in MockData.members)
            DropdownMenuItem(value: m.id, child: Text(m.name)),
        ],
        onChanged: (v) => setState(() => _assigneeId = v),
      ),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'Редагування завдання' : 'Нове завдання',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Додайте деталі та призначте відповідального.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрити',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Назва завдання',
                  labelAbove: true,
                  required: true,
                  controller: _title,
                  hint: 'Наприклад, полити квіти',
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Вкажіть назву завдання';
                    if (t.length > 80) {
                      return 'Назва занадто довга (до 80 символів)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Опис (необов\'язково)',
                  labelAbove: true,
                  controller: _description,
                  hint: 'Додайте короткий опис завдання',
                  maxLines: 3,
                  validator: (v) => (v?.length ?? 0) > 500
                      ? 'Опис занадто довгий (до 500 символів)'
                      : null,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    if (c.maxWidth < 440) {
                      return Column(
                        children: [
                          dateField,
                          const SizedBox(height: 16),
                          assigneeField,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: dateField),
                        const SizedBox(width: 16),
                        Expanded(child: assigneeField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Статус',
                  child: DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
                    isExpanded: true,
                    items: [
                      for (final s in TaskStatus.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      label: 'Скасувати',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    PrimaryButton(label: 'Зберегти', onPressed: _save),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

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
        child,
      ],
    );
  }
}
