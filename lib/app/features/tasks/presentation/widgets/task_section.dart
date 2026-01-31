// lib/app/features/tasks/presentation/widgets/task_section.dart
// Renders the daily tasks card beneath the plan summary on the journey screen.
// Exists to keep task loading/regeneration logic out of the main journey widget.
// RELEVANT FILES:lib/app/features/home/presentation/screens/journey_goal_tab.dart,lib/app/features/tasks/data/task_api_client.dart,lib/app/features/tasks/models/daily_task.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/tasks/data/task_api_client.dart';
import 'package:treespora/app/features/tasks/models/daily_task.dart';

class TaskSection extends StatefulWidget {
  const TaskSection({
    super.key,
    required this.goalId,
    required this.dayIndex,
    required this.apiClient,
    required this.isPlanLoading,
  });

  final String goalId;
  final int dayIndex;
  final TaskApiClient? apiClient;
  final bool isPlanLoading;

  @override
  State<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends State<TaskSection> {
  Future<List<DailyTask>>? _tasksFuture;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPlanLoading) {
      _reloadTasks();
    }
  }

  @override
  void didUpdateWidget(covariant TaskSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loadingChanged = oldWidget.isPlanLoading != widget.isPlanLoading;
    if (loadingChanged && widget.isPlanLoading) {
      setState(() {
        _tasksFuture = null;
      });
      return;
    }
    if (loadingChanged && !widget.isPlanLoading) {
      _reloadTasks();
      return;
    }
    if (oldWidget.goalId != widget.goalId ||
        oldWidget.dayIndex != widget.dayIndex ||
        oldWidget.apiClient != widget.apiClient) {
      _reloadTasks();
    }
  }

  void _reloadTasks() {
    if (widget.isPlanLoading) {
      setState(() {
        _tasksFuture = null;
      });
      return;
    }
    final client = widget.apiClient;
    if (client == null || !client.isConfigured) {
      setState(() {
        _tasksFuture = Future.value(const <DailyTask>[]);
      });
      return;
    }
    setState(() {
      _tasksFuture = client
          .fetchTasksForDay(goalId: widget.goalId, dayIndex: widget.dayIndex)
          .then((resp) => resp.tasks);
    });
  }

  Future<void> _handleGenerateTasks() async {
    final client = widget.apiClient;
    if (client == null || !client.isConfigured || _isRegenerating) return;
    setState(() {
      _isRegenerating = true;
    });
    try {
      await client.generateTaskPlan(goalId: widget.goalId);
      _showSnackBar('Tasks generated successfully.');
      _reloadTasks();
    } catch (error) {
      _showSnackBar('Could not generate tasks. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlanLoading) {
      return const _TaskSectionShell(
        child: _LoadingRow(label: 'Preparing your plan...'),
      );
    }

    final client = widget.apiClient;
    if (client == null || !client.isConfigured) {
      return const _TaskSectionShell(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Configure API_BASE_URL to load AI tasks.'),
        ),
      );
    }

    final future = _tasksFuture ?? Future.value(const <DailyTask>[]);
    return FutureBuilder<List<DailyTask>>(
      key: ValueKey('${widget.goalId}_${widget.dayIndex}'),
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TaskSectionShell(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is TaskPlanPendingException) {
            return _TaskSectionShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskSectionHeader(dayIndex: widget.dayIndex),
                  const SizedBox(height: 12),
                  const _LoadingRow(label: 'Generating tasks for this plan...'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isRegenerating ? null : _handleGenerateTasks,
                      child: _isRegenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Generate Tasks'),
                    ),
                  ),
                ],
              ),
            );
          }
          return _TaskSectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TaskSectionHeader(dayIndex: widget.dayIndex),
                const SizedBox(height: 12),
                Text(
                  'Could not load tasks for this day.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? const [];
        if (tasks.isEmpty) {
          return _TaskSectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TaskSectionHeader(dayIndex: widget.dayIndex),
                const SizedBox(height: 12),
                Text(
                  'No tasks generated for this day yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isRegenerating ? null : _handleGenerateTasks,
                    child: _isRegenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate Tasks'),
                  ),
                ),
              ],
            ),
          );
        }

        return _TaskSectionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaskSectionHeader(dayIndex: widget.dayIndex),
              const SizedBox(height: 12),
              ...tasks.map((task) => _TaskTile(task: task)),
            ],
          ),
        );
      },
    );
  }
}

class _TaskSectionShell extends StatelessWidget {
  const _TaskSectionShell({required this.child});

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

class _TaskSectionHeader extends StatelessWidget {
  const _TaskSectionHeader({required this.dayIndex});

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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final DailyTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDone = task.completedAt != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: isDone
                ? Icon(Icons.check, size: 14, color: scheme.primary)
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.estimatedMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.label});

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
