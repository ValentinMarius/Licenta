// lib/app/features/goals/domain/plan_summary.dart
// Defines the client-side representation of the backend plan summary schema.
// Exists so repositories and UI widgets can share strongly typed summaries.
// RELEVANT FILES:lib/app/features/goals/data/goal_repository.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart,lib/app/core/config/app_config.dart

class PlanPhase {
  const PlanPhase({
    required this.name,
    required this.focus,
    this.daysRange,
  });

  final String name;
  final String focus;
  final String? daysRange;

  factory PlanPhase.fromJson(Map<String, dynamic> json) {
    return PlanPhase(
      name: json['name'] as String? ?? 'Untitled phase',
      daysRange: json['days_range'] as String?,
      focus: json['focus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days_range': daysRange,
      'focus': focus,
    };
  }
}

class PlanSummary {
  const PlanSummary({
    required this.goalId,
    required this.overview,
    required this.phases,
    this.estimatedDurationDays,
  });

  final String goalId;
  final String overview;
  final List<PlanPhase> phases;
  final int? estimatedDurationDays;

  PlanSummary copyWith({
    String? goalId,
    String? overview,
    List<PlanPhase>? phases,
    int? estimatedDurationDays,
  }) {
    return PlanSummary(
      goalId: goalId ?? this.goalId,
      overview: overview ?? this.overview,
      phases: phases ?? this.phases,
      estimatedDurationDays: estimatedDurationDays ?? this.estimatedDurationDays,
    );
  }

  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    final phasesJson = json['phases'];
    return PlanSummary(
      goalId: json['goal_id'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      phases: phasesJson is List
          ? phasesJson
              .whereType<Map<String, dynamic>>()
              .map(PlanPhase.fromJson)
              .toList()
          : const [],
      estimatedDurationDays: json['estimated_duration_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'overview': overview,
      'phases': phases.map((phase) => phase.toJson()).toList(),
      'estimated_duration_days': estimatedDurationDays,
    };
  }
}
