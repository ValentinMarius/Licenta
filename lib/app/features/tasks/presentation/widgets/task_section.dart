// lib/app/features/tasks/presentation/widgets/task_section.dart
// Renders the daily tasks card beneath the plan summary on the journey screen.
// Exists to keep task loading/regeneration logic out of the main journey widget.
// RELEVANT FILES:lib/app/features/home/presentation/screens/journey_goal_tab.dart,lib/app/features/tasks/data/task_api_client.dart,lib/app/features/tasks/models/daily_task.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/tasks/data/task_api_client.dart';
import 'package:treespora/app/features/tasks/models/daily_task.dart';
import 'package:treespora/app/features/tasks/presentation/widgets/task_section_header.dart';
import 'package:treespora/app/features/tasks/presentation/widgets/task_section_shell.dart';
import 'package:treespora/app/features/tasks/presentation/widgets/task_tile.dart';
import 'package:treespora/app/features/tasks/state/task_progress_store.dart';

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
  final TaskProgressStore _progressStore = TaskProgressStore.instance;
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
      return const TaskSectionShell(
        child: TaskSectionLoadingRow(label: 'Preparing your plan...'),
      );
    }

    final client = widget.apiClient;
    if (client == null || !client.isConfigured) {
      return const TaskSectionShell(
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
          return const TaskSectionShell(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is TaskPlanPendingException) {
            return TaskSectionShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TaskSectionHeader(dayIndex: widget.dayIndex),
                  const SizedBox(height: 12),
                  const TaskSectionLoadingRow(
                    label: 'Generating tasks for this plan...',
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
          return TaskSectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaskSectionHeader(dayIndex: widget.dayIndex),
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
        _registerTasks(tasks);
        if (tasks.isEmpty) {
          return TaskSectionShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaskSectionHeader(dayIndex: widget.dayIndex),
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

        return TaskSectionShell(
          child: AnimatedBuilder(
            animation: _progressStore,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TaskSectionHeader(dayIndex: widget.dayIndex),
                  const SizedBox(height: 12),
                  for (var i = 0; i < tasks.length; i++)
                    TaskTile(
                      task: tasks[i],
                      status: _progressStore.statusFor(
                        goalId: widget.goalId,
                        dayIndex: widget.dayIndex,
                        taskKey: _taskKey(tasks[i], i),
                      ),
                      onStatusChanged: (status) {
                        _progressStore.setStatus(
                          goalId: widget.goalId,
                          dayIndex: widget.dayIndex,
                          taskKey: _taskKey(tasks[i], i),
                          status: status,
                        );
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _registerTasks(List<DailyTask> tasks) {
    if (tasks.isEmpty) return;
    final keys = <String>[];
    final completed = <String>{};
    for (var i = 0; i < tasks.length; i++) {
      final key = _taskKey(tasks[i], i);
      keys.add(key);
      if (tasks[i].completedAt != null) {
        completed.add(key);
      }
    }
    _progressStore.registerTasksForDay(
      goalId: widget.goalId,
      dayIndex: widget.dayIndex,
      taskKeys: keys,
      completedKeys: completed,
    );
  }

  String _taskKey(DailyTask task, int index) {
    if (task.id.isNotEmpty) {
      return task.id;
    }
    final safeDescription = task.description.trim();
    if (safeDescription.isNotEmpty) {
      return '${widget.dayIndex}-$index-$safeDescription';
    }
    return '${widget.dayIndex}-$index';
  }
}
