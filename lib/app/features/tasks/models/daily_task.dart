// lib/app/features/tasks/models/daily_task.dart
// Defines DTOs for the backend daily tasks API.
// Exists to keep HTTP parsing logic light and reusable across widgets.
// RELEVANT FILES:lib/app/features/tasks/data/task_api_client.dart,lib/app/features/tasks/presentation/widgets/task_section.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart

class DailyTask {
  const DailyTask({
    required this.id,
    required this.description,
    required this.estimatedMinutes,
    this.completedAt,
  });

  final String id;
  final String description;
  final int estimatedMinutes;
  final DateTime? completedAt;

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      estimatedMinutes: (json['estimated_minutes'] as int?) ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }
}

class TasksForDayResponse {
  const TasksForDayResponse({
    required this.goalId,
    required this.dayIndex,
    required this.tasks,
  });

  final String goalId;
  final int dayIndex;
  final List<DailyTask> tasks;

  factory TasksForDayResponse.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'] as List<dynamic>? ?? const [];
    return TasksForDayResponse(
      goalId: json['goal_id'] as String? ?? '',
      dayIndex: (json['day_index'] as int?) ?? 0,
      tasks: tasksJson
          .whereType<Map<String, dynamic>>()
          .map(DailyTask.fromJson)
          .toList(),
    );
  }
}
