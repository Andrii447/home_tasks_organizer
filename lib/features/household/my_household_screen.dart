import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models.dart';
import '../../state/household_controller.dart';

/// FR-07: інформація про домогосподарство та його учасників.
/// Стан — HouseholdController (Provider).
class MyHouseholdScreen extends StatelessWidget {
  const MyHouseholdScreen({super.key});

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> _rename(BuildContext context, Household household) async {
    final controller = context.read<HouseholdController>();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: household.name),
    );
    if (result == null || result.isEmpty) return;
    if (!await controller.rename(result) && context.mounted) {
      _toast(context, controller.error ?? 'Не вдалося змінити назву');
    }
  }

  static Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) _toast(context, 'Код приєднання скопійовано');
  }

  static Future<void> _remove(BuildContext context, Member member) async {
    final households = context.read<HouseholdController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити учасника?'),
        content: Text(
          '${member.name} втратить доступ до домогосподарства, а його '
          'незавершені завдання залишаться без виконавця.',
        ),
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
    if (ok != true) return;
    // Репозиторій також знімає виконавця з його завдань (FR-07).
    if (!await households.removeMember(member.id) && context.mounted) {
      _toast(context, households.error ?? 'Не вдалося видалити учасника');
    }
  }

  static String _membersLabel(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return '$n учасник';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n учасники';
    }
    return '$n учасників';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseholdController>();
    final household = controller.household;
    if (household == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final isOwner = controller.isOwner;
    final members = household.members;

    final nameCard = _InfoCard(
      label: 'Назва домогосподарства',
      value: household.name,
      action: isOwner
          ? SecondaryButton(
              label: 'Змінити назву',
              icon: Icons.edit_outlined,
              onPressed: () => _rename(context, household),
            )
          : const Text(
              'Змінювати назву може лише власник',
              style: TextStyle(color: AppColors.textSecondary),
            ),
    );
    final codeCard = _InfoCard(
      label: 'Код приєднання',
      value: household.inviteCode,
      action: SecondaryButton(
        label: 'Копіювати код',
        icon: Icons.copy_outlined,
        onPressed: () => _copyCode(context, household.inviteCode),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final gutter = wide ? 40.0 : AppSpacing.medium;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 32, gutter, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageHeader(
                      title: 'Мій дім',
                      subtitle: 'Керуйте інформацією про домогосподарство та його учасників',
                    ),
                    const SizedBox(height: 24),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: nameCard),
                          const SizedBox(width: 16),
                          Expanded(child: codeCard),
                        ],
                      )
                    else ...[
                      nameCard,
                      const SizedBox(height: 12),
                      codeCard,
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 32),
              sliver: DecoratedSliver(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(16),
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Учасники',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _membersLabel(members.length),
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final m = members[i];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 1, indent: 20, endIndent: 20),
                            _MemberTile(
                              member: m,
                              isOwner: household.isOwner(m.id),
                              isMe: m.id == controller.currentUserId,
                              onRemove: isOwner && !household.isOwner(m.id)
                                  ? () => _remove(context, m)
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.action,
  });

  final String label;
  final String value;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.isMe,
    this.onRemove,
  });

  final Member member;
  final bool isOwner;
  final bool isMe;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = [if (isOwner) 'Власник', if (isMe) 'Це ви'].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          UserAvatar(name: member.name, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.selected,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Власник',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else if (onRemove != null)
            IconButton(
              tooltip: 'Видалити учасника',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// Діалог зміни назви. Контролер належить State діалогу й знищується
/// в dispose(), тобто лише після завершення анімації закриття.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Змінити назву'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: AppTextField(
            label: 'Назва домогосподарства',
            controller: _controller,
            validator: Validators.householdName,
            onSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
        TextButton(onPressed: _submit, child: const Text('Зберегти')),
      ],
    );
  }
}
