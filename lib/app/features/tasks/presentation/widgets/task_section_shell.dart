// lib/app/features/tasks/presentation/widgets/task_section_shell.dart
// Provides shared containers for task sections and loading rows.
// Exists to keep TaskSection concise and reusable.
// RELEVANT FILES:lib/app/features/tasks/presentation/widgets/task_section.dart,lib/app/features/tasks/presentation/widgets/task_section_header.dart,lib/app/features/tasks/presentation/widgets/task_tile.dart

import 'package:flutter/material.dart';

class TaskSectionShell extends StatelessWidget {
  const TaskSectionShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: child,
    );
  }
}

class TaskSectionLoadingRow extends StatelessWidget {
  const TaskSectionLoadingRow({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
