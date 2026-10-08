import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// FR-07: інформація про домогосподарство та його учасників.
class MyHouseholdScreen extends StatefulWidget {
  const MyHouseholdScreen({super.key});

  @override
  State<MyHouseholdScreen> createState() => _MyHouseholdScreenState();
}

class _MyHouseholdScreenState extends State<MyHouseholdScreen> {
  String _name = MockData.householdName;
  final List<Member> _members = [...MockData.members];

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Змінити назву'),
        content: SizedBox(
          width: 360,
          child: AppTextField(
            label: 'Назва домогосподарства',
            controller: controller,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) setState(() => _name = result);
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(const ClipboardData(text: MockData.inviteCode));
    if (mounted) _toast('Код приєднання скопійовано');
  }

  Future<void> _remove(Member member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити учасника?'),
        content: Text('${member.name} втратить доступ до домогосподарства.'),
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
    if (ok == true) setState(() => _members.remove(member));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final nameCard = _InfoCard(
      label: 'Назва домогосподарства',
      value: _name,
      action: SecondaryButton(
        label: 'Змінити назву',
        icon: Icons.edit_outlined,
        onPressed: _rename,
      ),
    );
    final codeCard = _InfoCard(
      label: 'Код приєднання',
      value: MockData.inviteCode,
      action: SecondaryButton(
        label: 'Копіювати код',
        icon: Icons.copy_outlined,
        onPressed: _copyCode,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 40 : AppSpacing.medium,
            vertical: 32,
          ),
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
              const SizedBox(height: 20),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                            '${_members.length} учасники домогосподарства',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final m in _members) ...[
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _MemberTile(member: m, onRemove: () => _remove(m)),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
  const _MemberTile({required this.member, required this.onRemove});

  final Member member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
                if (member.isOwner)
                  const Text(
                    'Власник',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (member.isOwner)
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
          else
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
