// lib/app/features/tasks/data/task_api_client.dart
// Wraps the FastAPI endpoints responsible for serving daily tasks.
// Exists so UI widgets only depend on a tiny fetcher instead of raw http calls.
// RELEVANT FILES:lib/app/features/tasks/models/daily_task.dart,lib/app/features/tasks/presentation/widgets/task_section.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:treespora/app/core/config/app_config.dart';

import 'package:treespora/app/features/tasks/models/daily_task.dart';

class TaskApiException implements Exception {
  const TaskApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TaskPlanPendingException extends TaskApiException {
  const TaskPlanPendingException(String message) : super(message);
}

class TaskApiClient {
  TaskApiClient({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).trim(),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Uri _buildUri(String path) {
    final normalized =
        _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    return Uri.parse('$normalized$path');
  }

  Uri _tasksUri(String goalId, int dayIndex) {
    return _buildUri('/v1/goals/$goalId/tasks').replace(
      queryParameters: {
        'day_index': dayIndex.toString(),
      },
    );
  }

  Uri _taskPlanUri(String goalId) {
    return _buildUri('/v1/goals/$goalId/task_plan');
  }

  Future<TasksForDayResponse> fetchTasksForDay({
    required String goalId,
    required int dayIndex,
  }) async {
    if (!isConfigured) {
      throw const TaskApiException(
        'API base URL missing. Provide API_BASE_URL via --dart-define.',
      );
    }
    final uri = _tasksUri(goalId, dayIndex);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw const TaskPlanPendingException(
          'Tasks are not ready yet for this plan.',
        );
      }
      throw TaskApiException(
        'Failed to load tasks (status ${response.statusCode}).',
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return TasksForDayResponse.fromJson(payload);
  }

  Future<void> generateTaskPlan({required String goalId}) async {
    if (!isConfigured) {
      throw const TaskApiException(
        'API base URL missing. Provide API_BASE_URL via --dart-define.',
      );
    }
    final uri = _taskPlanUri(goalId);
    final response = await _client.post(uri);
    if (response.statusCode != 200) {
      throw TaskApiException(
        'Failed to generate tasks (status ${response.statusCode}).',
      );
    }
  }
}
