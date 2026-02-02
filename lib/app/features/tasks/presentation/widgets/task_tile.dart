// lib/app/features/tasks/presentation/widgets/task_tile.dart
// Renders a tappable task row with a selectable completion status.
// Exists to isolate status selection UI and keep TaskSection lean.
// RELEVANT FILES:lib/app/features/tasks/presentation/widgets/task_section.dart,lib/app/features/tasks/state/task_progress_store.dart,lib/app/features/tasks/models/daily_task.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/tasks/models/daily_task.dart';
import 'package:treespora/app/features/tasks/state/task_progress_store.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.status,
    required this.onStatusChanged,
    this.isEditable = true,
    this.notDoneLabel,
  });

  final DailyTask task;
  final TaskCompletionStatus status;
  final ValueChanged<TaskCompletionStatus> onStatusChanged;
  final bool isEditable;
  final String? notDoneLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor(scheme);
    final statusIcon = _statusIcon();
    final label = _labelForStatus();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isEditable ? () => _showStatusSheet(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 4, right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor),
                ),
                child: statusIcon,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        decoration: status == TaskCompletionStatus.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${task.estimatedMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: statusColor.withOpacity(0.45),
                            ),
                          ),
                      child: Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Task status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _StatusOptionTile(
                status: TaskCompletionStatus.completed,
                current: status,
                onSelected: () => _selectStatus(
                  context,
                  TaskCompletionStatus.completed,
                ),
              ),
              _StatusOptionTile(
                status: TaskCompletionStatus.partial,
                current: status,
                onSelected: () => _selectStatus(
                  context,
                  TaskCompletionStatus.partial,
                ),
              ),
              _StatusOptionTile(
                status: TaskCompletionStatus.notDone,
                current: status,
                onSelected: () => _selectStatus(
                  context,
                  TaskCompletionStatus.notDone,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectStatus(BuildContext context, TaskCompletionStatus next) {
    if (!isEditable) return;
    onStatusChanged(next);
    Navigator.of(context).pop();
  }

  String _labelForStatus() {
    if (status == TaskCompletionStatus.notDone && notDoneLabel != null) {
      return notDoneLabel!;
    }
    return status.label;
  }

  Color _statusColor(ColorScheme scheme) {
    switch (status) {
      case TaskCompletionStatus.completed:
        return scheme.primary;
      case TaskCompletionStatus.partial:
        return scheme.secondary;
      case TaskCompletionStatus.notDone:
        return scheme.outlineVariant;
    }
  }

  Widget? _statusIcon() {
    switch (status) {
      case TaskCompletionStatus.completed:
        return const Icon(Icons.check, size: 14);
      case TaskCompletionStatus.partial:
        return const Icon(Icons.horizontal_rule_rounded, size: 14);
      case TaskCompletionStatus.notDone:
        return null;
    }
  }
}

class _StatusOptionTile extends StatelessWidget {
  const _StatusOptionTile({
    required this.status,
    required this.current,
    required this.onSelected,
  });

  final TaskCompletionStatus status;
  final TaskCompletionStatus current;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = status == current;
    final color = isSelected ? scheme.primary : scheme.onSurfaceVariant;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_statusIcon(status), color: color),
      title: Text(
        status.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: scheme.primary) : null,
      onTap: onSelected,
    );
  }

  IconData _statusIcon(TaskCompletionStatus status) {
    switch (status) {
      case TaskCompletionStatus.completed:
        return Icons.check_circle_rounded;
      case TaskCompletionStatus.partial:
        return Icons.pause_circle_filled_rounded;
      case TaskCompletionStatus.notDone:
        return Icons.radio_button_unchecked;
    }
  }
}
