// lib/app/features/tasks/data/task_api_client.dart
// Wraps the FastAPI endpoints responsible for serving daily tasks.
// Exists so UI widgets only depend on a tiny fetcher instead of raw http calls.
// RELEVANT FILES:lib/app/features/tasks/models/daily_task.dart,lib/app/features/tasks/presentation/widgets/task_section.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  TaskApiClient({String? baseUrl, http.Client? client})
    : _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).trim(),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  static const int planWindowDays = 14;
  static const int prefetchLeadDays = 3;

  bool get isConfigured => _baseUrl.isNotEmpty;

  String _tasksCacheKey(String goalId, int dayIndex) {
    return 'tasks_${goalId}_$dayIndex';
  }

  Future<TasksForDayResponse?> _readCachedTasks(
    String goalId,
    int dayIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksCacheKey(goalId, dayIndex));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return TasksForDayResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedTasks(
    String goalId,
    int dayIndex,
    String body,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksCacheKey(goalId, dayIndex), body);
  }

  Uri _buildUri(String path) {
    final normalized = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$normalized$path');
  }

  Uri _tasksUri(String goalId, int dayIndex) {
    return _buildUri(
      '/v1/goals/$goalId/tasks',
    ).replace(queryParameters: {'day_index': dayIndex.toString()});
  }

  Uri _taskPlanUri(String goalId) {
    return _buildUri('/v1/goals/$goalId/task_plan');
  }

  Uri _taskPlanUriWithParams(
    String goalId, {
    int? startDayIndex,
    int? windowDays,
  }) {
    final uri = _taskPlanUri(goalId);
    final params = <String, String>{};
    if (startDayIndex != null) {
      params['start_day_index'] = startDayIndex.toString();
    }
    if (windowDays != null) {
      params['window_days'] = windowDays.toString();
    }
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  String _errorMessageFromResponse(http.Response response, String fallback) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic>) {
        final detail = payload['detail'];
        if (detail is Map<String, dynamic>) {
          final message = detail['message']?.toString();
          if (message != null && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
        final message = payload['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return fallback;
    }
    return fallback;
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
    final cached = await _readCachedTasks(goalId, dayIndex);
    if (cached != null) {
      return cached;
    }
    final uri = _tasksUri(goalId, dayIndex);
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw const TaskPlanPendingException(
            'Tasks are not ready yet for this plan.',
          );
        }
        final message = _errorMessageFromResponse(
          response,
          'Failed to load tasks (status ${response.statusCode}).',
        );
        throw TaskApiException(message);
      }
      await _writeCachedTasks(goalId, dayIndex, response.body);
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return TasksForDayResponse.fromJson(payload);
    } on TimeoutException catch (_) {
      throw const TaskPlanPendingException(
        'Tasks are still loading for this day. Please try again in a moment.',
      );
    } catch (error) {
      debugPrint('TaskApiClient.fetchTasksForDay failed: $error');
      rethrow;
    }
  }

  Future<void> generateTaskPlan({
    required String goalId,
    int? startDayIndex,
    int? windowDays,
  }) async {
    if (!isConfigured) {
      throw const TaskApiException(
        'API base URL missing. Provide API_BASE_URL via --dart-define.',
      );
    }
    final uri = _taskPlanUriWithParams(
      goalId,
      startDayIndex: startDayIndex,
      windowDays: windowDays,
    );
    final response = await _client
        .post(uri)
        .timeout(const Duration(seconds: 100));
    if (response.statusCode != 200) {
      final message = _errorMessageFromResponse(
        response,
        'Failed to generate tasks (status ${response.statusCode}).',
      );
      throw TaskApiException(message);
    }
  }
}
