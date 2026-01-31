// lib/app/features/home/presentation/screens/home_screen.dart
// Presents the Treespora home tab with streak header and goal progress.
// Exists to surface progress updates that reflect task completion choices.
// RELEVANT FILES:lib/app/features/home/root/main_tab_shell.dart,lib/app/features/home/presentation/widgets/home_streak_header.dart,lib/app/features/tasks/state/task_progress_store.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/goals/data/plan_repository.dart';
import 'package:treespora/app/features/goals/state/active_goal_controller.dart';
import 'package:treespora/app/features/home/presentation/widgets/home_streak_header.dart';
import 'package:treespora/app/features/tasks/state/task_progress_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const StreakSnapshot _streakSample =
      StreakSnapshot(current: 5, best: 14);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlanRepository _planRepository = PlanRepository.instance;
  final TaskProgressStore _progressStore = TaskProgressStore.instance;
  String? _goalId;
  PlanInfo? _plan;
  bool _loadingPlan = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ActiveGoalControllerProvider.of(context);
    final activeGoalId = controller.activeGoalId;
    if (activeGoalId != _goalId) {
      _goalId = activeGoalId;
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    final goalId = _goalId;
    if (goalId == null) {
      setState(() {
        _plan = null;
        _loadingPlan = false;
      });
      return;
    }
    setState(() {
      _loadingPlan = true;
    });
    final plan = await _planRepository.fetchActivePlanForGoal(goalId);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loadingPlan = false;
    });
  }

  int _planTotalDays(PlanInfo plan) {
    return plan.durationDays > 0 ? plan.durationDays : 1;
  }

  @override
  Widget build(BuildContext context) {
    final goalId = _goalId;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeStreakHeader(
            streak: HomeScreen._streakSample,
          ),
          const SizedBox(height: 24),
          if (goalId == null)
            const _HomePlaceholder(
              title: 'Pick a goal to track progress',
              subtitle: 'Select a goal in Forest to see your plan progress.',
            )
          else if (_loadingPlan)
            const Center(child: CircularProgressIndicator())
          else if (_plan == null)
            const _HomePlaceholder(
              title: 'No active plan yet',
              subtitle: 'Create a plan in Forest to start tracking progress.',
            )
          else
            AnimatedBuilder(
              animation: _progressStore,
              builder: (context, child) {
                final totalDays = _planTotalDays(_plan!);
                final completedDays = _progressStore.completedDaysForGoal(
                  goalId: goalId,
                  totalDays: totalDays,
                );
                final progress = _progressStore.progressForGoal(
                  goalId: goalId,
                  totalDays: totalDays,
                );
                return _HomeProgressCard(
                  completedDays: completedDays,
                  totalDays: totalDays,
                  progress: progress,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HomeProgressCard extends StatelessWidget {
  const _HomeProgressCard({
    required this.completedDays,
    required this.totalDays,
    required this.progress,
  });

  final int completedDays;
  final int totalDays;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: scheme.surface,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            '$completedDays of $totalDays days complete',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent% overall progress',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
