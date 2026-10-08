import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../theme/app_colors.dart';

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      TaskStatus.planned => (AppColors.plannedBg, AppColors.plannedFg),
      TaskStatus.inProgress => (AppColors.inProgressBg, AppColors.inProgressFg),
      TaskStatus.completed => (AppColors.completedBg, AppColors.completedFg),
    };
    return _Pill(text: status.label, bg: bg, fg: fg);
  }
}

class OverdueChip extends StatelessWidget {
  const OverdueChip({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Pill(
      text: 'Прострочено',
      bg: AppColors.dangerSoft,
      fg: AppColors.danger,
    );
  }
}
