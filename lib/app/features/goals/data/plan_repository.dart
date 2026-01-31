// lib/app/features/goals/data/plan_repository.dart
// Fetches plans, day check-ins, and tasks from Supabase for the active goal.
// Exists to keep UI layers simple while reusing the existing schema (plans, day_check_ins, tasks, ai_plans).
// RELEVANT FILES:lib/app/features/home/presentation/screens/journey_goal_tab.dart,lib/app/features/home/presentation/widgets/home_calendar_strip.dart,lib/app/features/profile/data/profile_repository.dart

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

class PlanInfo {
  const PlanInfo({
    required this.id,
    required this.goalId,
    required this.startDate,
    required this.durationDays,
    required this.targetDate,
    required this.summary,
    required this.goalDescription,
    required this.goalTitle,
  });

  final String id;
  final String goalId;
  final DateTime startDate;
  final int durationDays;
  final DateTime targetDate;
  final String summary;
  final String goalDescription;
  final String goalTitle;
}

class DayCheckIn {
  const DayCheckIn({
    required this.id,
    required this.dayIndex,
    required this.date,
    required this.progressScore,
    required this.completedTasks,
    required this.plannedTasks,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final int dayIndex;
  final DateTime? date;
  final String? progressScore;
  final int? completedTasks;
  final int? plannedTasks;
  final String? notes;
  final DateTime? createdAt;

  factory DayCheckIn.fromMap(Map<String, dynamic> map) {
    return DayCheckIn(
      id: map['id']?.toString() ?? '',
      dayIndex: (map['day_index'] as int?) ?? 0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString())
          : null,
      progressScore: map['progress_score'] as String?,
      completedTasks: map['completed_tasks'] as int?,
      plannedTasks: map['planned_tasks'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.dayIndex,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final int dayIndex;
  final String description;
  final String status;
  final DateTime? createdAt;

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id']?.toString() ?? '',
      dayIndex: (map['day_index'] as int?) ?? 0,
      description: (map['description'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class PlanRepository {
  PlanRepository._(this._client);

  final SupabaseClient? _client;
  static PlanRepository? _instance;
  static const int _fallbackDurationDays = 30;

  static PlanRepository get instance {
    _instance ??= PlanRepository._(_resolveClient());
    return _instance!;
  }

  static SupabaseClient? _resolveClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _configured => AppConfig.hasSupabaseKeys && _client != null;

  Future<PlanInfo?> fetchActivePlanForGoal(String goalId) async {
    if (!_configured) return null;
    final supabase = _client!;

    try {
      final goal = await supabase
          .from('goals')
          .select(
            'current_plan_id,title,description,target_date,created_at,start_date',
          )
          .eq('id', goalId)
          .maybeSingle();
      if (goal == null || goal is! Map<String, dynamic>) {
        return null;
      }
      final goalTitle = (goal['title'] as String?) ?? 'Goal';
      final goalDescription = (goal['description'] as String?) ?? '';
      final goalTargetDate = _parseDate(goal['target_date']);
      final goalCreatedAt = _parseDate(goal['created_at']);
      final goalStartDate = _parseDate(goal['start_date']);
      final currentPlanId = goal['current_plan_id'] as String?;

      final PlanInfo? fromAi = await _planFromAiPlans(
        supabase: supabase,
        goalId: goalId,
        goalTitle: goalTitle,
        goalDescription: goalDescription,
        currentPlanId: currentPlanId,
        goalTargetDate: goalTargetDate,
        goalCreatedAt: goalCreatedAt,
        goalStartDate: goalStartDate,
      );
      if (fromAi != null) {
        return fromAi;
      }

      return await _planFromPlansTable(
        supabase: supabase,
        goalId: goalId,
        goalTitle: goalTitle,
        goalDescription: goalDescription,
        currentPlanId: currentPlanId,
        goalTargetDate: goalTargetDate,
        goalCreatedAt: goalCreatedAt,
        goalStartDate: goalStartDate,
      );
    } catch (_) {
      return null;
    }
  }

  Future<PlanInfo?> _planFromAiPlans({
    required SupabaseClient supabase,
    required String goalId,
    required String goalTitle,
    required String goalDescription,
    String? currentPlanId,
    DateTime? goalTargetDate,
    DateTime? goalCreatedAt,
    DateTime? goalStartDate,
  }) async {
    Map<String, dynamic>? aiPlanRow;
    if (currentPlanId != null && currentPlanId.isNotEmpty) {
      aiPlanRow = await supabase
          .from('ai_plans')
          .select('id,goal_id,summary,plan_json,target_date')
          .eq('id', currentPlanId)
          .maybeSingle();
    }
    aiPlanRow ??= await supabase
        .from('ai_plans')
        .select('id,goal_id,summary,plan_json,target_date')
        .eq('goal_id', goalId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final summary = (aiPlanRow != null && aiPlanRow is Map<String, dynamic>)
        ? (aiPlanRow['summary'] as String?) ?? goalDescription
        : goalDescription;

    final dateRange = await _inferDatesFromData(supabase, goalId);
    final planJson = _decodePlanJson(aiPlanRow?['plan_json']);
    final jsonStart = _planJsonDate(planJson, 'start_date');
    final jsonHorizon = _coercePositiveInt(planJson?['time_horizon_days']);
    final startDate =
        goalStartDate ??
        jsonStart ??
        dateRange?.start ??
        goalCreatedAt ??
        DateTime.now();
    final normalizedStart = _asDateOnly(startDate);
    final planTarget = _parseDate(aiPlanRow?['target_date']) ?? goalTargetDate;
    final preferredDuration = jsonHorizon ?? dateRange?.durationDays;
    final durationDays = _resolveDurationDays(
      normalizedStart,
      planTarget,
      preferredDuration,
    );
    final resolvedTarget = _resolveTargetDate(
      normalizedStart,
      planTarget,
      durationDays,
    );

    return PlanInfo(
      id: (aiPlanRow?['id'] as String?) ?? 'ai-plan-$goalId',
      goalId: goalId,
      startDate: normalizedStart,
      durationDays: durationDays,
      targetDate: resolvedTarget,
      summary: summary,
      goalDescription: goalDescription,
      goalTitle: goalTitle,
    );
  }

  Future<PlanInfo?> _planFromPlansTable({
    required SupabaseClient supabase,
    required String goalId,
    required String goalTitle,
    required String goalDescription,
    String? currentPlanId,
    DateTime? goalTargetDate,
    DateTime? goalCreatedAt,
    DateTime? goalStartDate,
  }) async {
    Map<String, dynamic>? planRow;
    if (currentPlanId != null && currentPlanId.isNotEmpty) {
      planRow = await supabase
          .from('plans')
          .select('id,goal_id,start_date,duration_days,summary,target_date')
          .eq('id', currentPlanId)
          .maybeSingle();
    }

    planRow ??= await supabase
        .from('plans')
        .select('id,goal_id,start_date,duration_days,summary,target_date')
        .eq('goal_id', goalId)
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (planRow == null || planRow is! Map<String, dynamic>) {
      return null;
    }

    final start =
        _parseDate(planRow['start_date']) ?? goalStartDate ?? goalCreatedAt;
    if (start == null) {
      return null;
    }
    final planTarget = _parseDate(planRow['target_date']) ?? goalTargetDate;
    final explicitDuration = _coercePositiveInt(planRow['duration_days']);
    final normalizedStart = _asDateOnly(start);
    final durationDays = _resolveDurationDays(
      normalizedStart,
      planTarget,
      explicitDuration,
    );
    final resolvedTarget = _resolveTargetDate(
      normalizedStart,
      planTarget,
      durationDays,
    );

    return PlanInfo(
      id: planRow['id'] as String,
      goalId: planRow['goal_id'] as String,
      startDate: normalizedStart,
      durationDays: durationDays,
      targetDate: resolvedTarget,
      summary: (planRow['summary'] as String?) ?? goalDescription,
      goalDescription: goalDescription,
      goalTitle: goalTitle,
    );
  }

  Future<_PlanDates?> _inferDatesFromData(
    SupabaseClient supabase,
    String goalId,
  ) async {
    try {
      final dayRows = await supabase
          .from('day_check_ins')
          .select('date,day_index')
          .eq('goal_id', goalId)
          .order('day_index', ascending: true);
      DateTime? startDate;
      int? highestDayIndex;
      if (dayRows is List && dayRows.isNotEmpty) {
        for (final row in dayRows.whereType<Map<String, dynamic>>()) {
          final parsed = _parseDate(row['date']);
          startDate ??= parsed;
          final dayIndex = row['day_index'] as int?;
          if (dayIndex != null) {
            highestDayIndex = highestDayIndex == null
                ? dayIndex
                : (dayIndex > highestDayIndex! ? dayIndex : highestDayIndex);
          }
        }
      }

      if (startDate == null) {
        final taskRows = await supabase
            .from('tasks')
            .select('created_at,day_index')
            .eq('goal_id', goalId)
            .order('created_at', ascending: true);
        if (taskRows is List && taskRows.isNotEmpty) {
          final first = taskRows.cast<Map<String, dynamic>?>().firstWhere(
            (e) => e != null,
          );
          startDate = _parseDate(first?['created_at']);
          for (final row in taskRows.whereType<Map<String, dynamic>>()) {
            final idx = row['day_index'] as int?;
            if (idx != null) {
              highestDayIndex = highestDayIndex == null
                  ? idx
                  : (idx > highestDayIndex! ? idx : highestDayIndex);
            }
          }
        }
      }

      if (startDate == null) {
        return null;
      }
      final normalizedStart = _asDateOnly(startDate);
      final duration = highestDayIndex != null && highestDayIndex! >= 0
          ? highestDayIndex! + 1
          : _fallbackDurationDays;
      return _PlanDates(start: normalizedStart, durationDays: duration);
    } catch (_) {
      return null;
    }
  }

  Future<List<DayCheckIn>> fetchDayCheckIns({
    required String goalId,
    required String planId,
    required int dayIndex,
  }) async {
    if (!_configured) return const [];
    final userId = _client?.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final response = await _client!
          .from('day_check_ins')
          .select()
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .eq('plan_id', planId)
          .eq('day_index', dayIndex)
          .order('created_at', ascending: false);
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map(DayCheckIn.fromMap)
            .toList();
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  Future<List<TaskItem>> fetchTasksForDay({
    required String planId,
    required int dayIndex,
  }) async {
    if (!_configured) return const [];
    try {
      final response = await _client!
          .from('tasks')
          .select()
          .eq('plan_id', planId)
          .eq('day_index', dayIndex)
          .order('order_in_day', ascending: true);
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map(TaskItem.fromMap)
            .toList();
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  DateTime _asDateOnly(DateTime source) {
    return DateTime(source.year, source.month, source.day);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return _asDateOnly(value);
    }
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return _asDateOnly(parsed);
      }
    }
    return null;
  }

  int? _coercePositiveInt(dynamic value) {
    if (value is int && value > 0) {
      return value;
    }
    if (value is double && value > 0) {
      return value.round();
    }
    return null;
  }

  int _resolveDurationDays(
    DateTime startDate,
    DateTime? targetDate,
    int? preferredDays,
  ) {
    if (targetDate != null && !targetDate.isBefore(startDate)) {
      // Duration is inclusive of both start and target dates.
      return targetDate.difference(startDate).inDays + 1;
    }
    if (preferredDays != null && preferredDays > 0) {
      return preferredDays;
    }
    return _fallbackDurationDays;
  }

  DateTime _resolveTargetDate(
    DateTime startDate,
    DateTime? explicitTarget,
    int durationDays,
  ) {
    final safeDuration = durationDays > 0 ? durationDays : 1;
    final computed = startDate.add(Duration(days: safeDuration - 1));
    if (explicitTarget != null && !explicitTarget.isBefore(startDate)) {
      final diff = explicitTarget.difference(startDate).inDays + 1;
      if (diff == safeDuration) {
        return explicitTarget;
      }
    }
    return computed;
  }

  Map<String, dynamic>? _decodePlanJson(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DateTime? _planJsonDate(Map<String, dynamic>? planJson, String key) {
    if (planJson == null) {
      return null;
    }
    return _parseDate(planJson[key]);
  }
}

class _PlanDates {
  const _PlanDates({required this.start, required this.durationDays});
  final DateTime start;
  final int durationDays;
}
