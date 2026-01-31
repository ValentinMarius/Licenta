// lib/app/features/tasks/presentation/widgets/task_section_header.dart
// Shows the day label and task count hint for the task list section.
// Exists to keep TaskSection layout readable and under the line limit.
// RELEVANT FILES:lib/app/features/tasks/presentation/widgets/task_section.dart,lib/app/features/tasks/presentation/widgets/task_tile.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart

import 'package:flutter/material.dart';

class TaskSectionHeader extends StatelessWidget {
  const TaskSectionHeader({
    super.key,
    required this.dayIndex,
  });

  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = 'Tasks • Day ${dayIndex + 1}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '1–3 tasks',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
