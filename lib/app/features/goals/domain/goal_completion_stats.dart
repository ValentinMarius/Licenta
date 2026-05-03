// lib/app/features/goals/domain/goal_completion_stats.dart
// Defines the stats breakdown for completed goals by planned duration.
// Exists to keep profile UI decoupled from raw duration math.
// RELEVANT FILES:lib/app/features/goals/data/goal_repository.dart,lib/app/features/profile/presentation/screens/profile_content.dart

class GoalCompletionStats {
  const GoalCompletionStats({
    required this.totalCompleted,
    required this.completedIn7Days,
    required this.completedIn8To31Days,
    required this.completedIn32To365Days,
  });

  final int totalCompleted;
  final int completedIn7Days;
  final int completedIn8To31Days;
  final int completedIn32To365Days;

  int get treesFromWeeklyGoals => completedIn7Days ~/ 4;
  int get treesFromMonthlyGoals => completedIn8To31Days;
  int get treesFromYearlyGoals => completedIn32To365Days * 12;

  int get totalTrees =>
      treesFromWeeklyGoals + treesFromMonthlyGoals + treesFromYearlyGoals;

  static const GoalCompletionStats empty = GoalCompletionStats(
    totalCompleted: 0,
    completedIn7Days: 0,
    completedIn8To31Days: 0,
    completedIn32To365Days: 0,
  );
}
