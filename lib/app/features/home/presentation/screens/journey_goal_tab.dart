// lib/app/features/home/presentation/screens/journey_goal_tab.dart
// Shows the journey view with week header, calendar, plan summary, and day check-ins.
// Exists to keep users aligned to their plan using only existing plan/check-in/task tables.
// RELEVANT FILES:lib/app/features/home/presentation/widgets/home_calendar_strip.dart,lib/app/features/home/presentation/widgets/home_week_header.dart,lib/app/features/goals/data/plan_repository.dart,lib/app/features/goals/data/goal_repository.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:treespora/app/features/goals/data/goal_repository.dart';
import 'package:treespora/app/features/goals/data/plan_repository.dart';
import 'package:treespora/app/features/goals/domain/plan_summary.dart';
import 'package:treespora/app/features/goals/state/active_goal_controller.dart';
import 'package:treespora/app/features/home/presentation/widgets/home_calendar_strip.dart';
import 'package:treespora/app/features/home/presentation/widgets/home_week_header.dart';
import 'package:treespora/app/features/tasks/data/task_api_client.dart';
import 'package:treespora/app/features/tasks/presentation/widgets/task_section.dart';

class JourneyGoalTab extends StatefulWidget {
  const JourneyGoalTab({super.key});

  @override
  State<JourneyGoalTab> createState() => _JourneyGoalTabState();
}

class _JourneyGoalTabState extends State<JourneyGoalTab> {
  final PlanRepository _planRepository = PlanRepository.instance;
  final GoalRepository _goalRepository = GoalRepository.instance;
  late final TaskApiClient _taskApiClient;

  PlanInfo? _plan;
  String? _goalId;
  bool _loadingPlan = false;
  Future<PlanSummary?>? _planSummaryFuture;
  bool _planSummaryLoading = false;
  int _selectedDayIndex = 0;
  List<HomeCalendarDay> _calendarDays = const [];

  @override
  void initState() {
    super.initState();
    _taskApiClient = TaskApiClient();
  }

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
    if (goalId == null) return;
    setState(() {
      _loadingPlan = true;
      _planSummaryLoading = true;
    });
    final plan = await _planRepository.fetchActivePlanForGoal(goalId);
    if (!mounted) return;
    if (plan == null) {
      setState(() {
        _loadingPlan = false;
        _plan = null;
        _calendarDays = const [];
        _planSummaryFuture = null;
        _planSummaryLoading = false;
      });
      return;
    }
    final days = _buildCalendarDays(plan);
    final defaultDayIndex = _deriveDefaultDayIndex(plan);
    _selectedDayIndex = defaultDayIndex;
    _plan = plan;
    _calendarDays = days;
    _loadingPlan = false;
    final future = _goalRepository.fetchPlanSummary(goalId);
    _planSummaryFuture = future;
    future.whenComplete(() {
      if (!mounted) return;
      setState(() {
        _planSummaryLoading = false;
      });
    });
    setState(() {});
  }

  int _deriveDefaultDayIndex(PlanInfo plan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planStart = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final planTarget = DateTime(
      plan.targetDate.year,
      plan.targetDate.month,
      plan.targetDate.day,
    );
    final planEndExclusive = planTarget.add(const Duration(days: 1));
    if (!today.isBefore(planStart) && today.isBefore(planEndExclusive)) {
      return today.difference(planStart).inDays;
    }
    return 0;
  }

  int _planTotalDays(PlanInfo plan) {
    return plan.durationDays > 0 ? plan.durationDays : 1;
  }

  List<HomeCalendarDay> _buildCalendarDays(PlanInfo plan) {
    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final list = <HomeCalendarDay>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalDays = _planTotalDays(plan);
    for (var i = 0; i < totalDays; i++) {
      final date = start.add(Duration(days: i));
      final isToday = DateUtils.isSameDay(date, today);
      final status = isToday
          ? HomeDayStatus.partial
          : date.isBefore(today)
          ? HomeDayStatus.completed
          : HomeDayStatus.upcoming;
      list.add(
        HomeCalendarDay(
          label: DateFormat('E').format(date),
          planDayIndex: i,
          dayNumber: date.day,
          status: status,
          date: date,
          isToday: isToday,
        ),
      );
    }
    return list;
  }

  void _onDaySelected(HomeCalendarDay day) {
    setState(() {
      _selectedDayIndex = day.planDayIndex;
    });
  }

  void _onWeekChanged(int weekIndex) {
    if (_plan == null) return;
    final startDayIndex = (weekIndex - 1) * 7;
    final totalDays = _planTotalDays(_plan!);
    final safeDay = totalDays > 0
        ? startDayIndex.clamp(0, totalDays - 1).toInt()
        : 0;
    final target = _calendarDays.firstWhere(
      (d) => d.planDayIndex == safeDay,
      orElse: () => _calendarDays.first,
    );
    _onDaySelected(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_goalId == null) {
      return _PlaceholderCard(
        message:
            'Select a goal in the Forest tab to view your plan, weeks, and check-ins.',
      );
    }
    if (_loadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_plan == null) {
      return _PlaceholderCard(
        message: 'No active plan found for this goal yet.',
      );
    }

    final weekIndex = (_selectedDayIndex ~/ 7) + 1;
    final startDayZero = (weekIndex - 1) * 7;
    final totalDays = _planTotalDays(_plan!);
    final safeMaxIndex = totalDays > 0 ? totalDays - 1 : 0;
    final endDayZero = safeMaxIndex >= 0
        ? (startDayZero + 6).clamp(0, safeMaxIndex).toInt()
        : 0;
    final startDay = (startDayZero + 1).clamp(1, totalDays).toInt();
    final endDay = (endDayZero + 1).clamp(1, totalDays).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeWeekHeader(
            weekIndex: weekIndex,
            startDay: startDay,
            endDay: endDay,
            totalDays: totalDays,
          ),
          const SizedBox(height: 12),
          HomeCalendarStrip(
            days: _calendarDays,
            selectedDayIndex: _selectedDayIndex,
            onDaySelected: _onDaySelected,
            onWeekChanged: _onWeekChanged,
          ),
          const SizedBox(height: 20),
          _PlanSummarySection(
            future: _planSummaryFuture,
            fallbackSummary: _plan!.summary,
            fallbackDescription: _plan!.goalDescription,
          ),
          if (_goalId != null)
            Builder(
              builder: (context) {
                final selected = _calendarDays.firstWhere(
                  (d) => d.planDayIndex == _selectedDayIndex,
                  orElse: () => _calendarDays.first,
                );
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final date = DateTime(
                  selected.date.year,
                  selected.date.month,
                  selected.date.day,
                );
                final isToday = DateUtils.isSameDay(date, today);
                final isPast = date.isBefore(today);
                return TaskSection(
                  goalId: _goalId!,
                  dayIndex: _selectedDayIndex,
                  apiClient: _taskApiClient,
                  isPlanLoading: _loadingPlan || _planSummaryLoading,
                  isEditable: isToday,
                  isPastDay: isPast,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PlanSummarySection extends StatefulWidget {
  const _PlanSummarySection({
    required this.future,
    required this.fallbackSummary,
    required this.fallbackDescription,
  });

  final Future<PlanSummary?>? future;
  final String fallbackSummary;
  final String fallbackDescription;

  @override
  State<_PlanSummarySection> createState() => _PlanSummarySectionState();
}

class _PlanSummarySectionState extends State<_PlanSummarySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final collapsed = !_expanded;
    if (widget.future == null) {
      return _PlanSummaryContainer(
        onTap: _toggle,
        child: _PlanSummaryContent(
          summary: PlanSummary(
            goalId: '',
            overview: widget.fallbackSummary.isNotEmpty
                ? widget.fallbackSummary
                : (widget.fallbackDescription.isNotEmpty
                      ? widget.fallbackDescription
                      : 'Plan summary'),
            phases: const [],
            estimatedDurationDays: null,
          ),
          collapsed: collapsed,
        ),
      );
    }
    return FutureBuilder<PlanSummary?>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PlanSummaryContainer(
            onTap: null,
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final summary = snapshot.data;
        if (summary == null) {
          return _PlanSummaryContainer(
            onTap: _toggle,
            child: _PlanSummaryContent(
              summary: _fallbackSummary(),
              collapsed: collapsed,
            ),
          );
        }
        final effective = _withFallback(summary);
        return _PlanSummaryContainer(
          onTap: _toggle,
          child: _PlanSummaryContent(summary: effective, collapsed: collapsed),
        );
      },
    );
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  PlanSummary _withFallback(PlanSummary summary) {
    final trimmed = summary.overview.trim();
    if (trimmed.isNotEmpty) return summary;
    return _fallbackSummary().copyWith(
      estimatedDurationDays: summary.estimatedDurationDays,
    );
  }

  PlanSummary _fallbackSummary() {
    final text = widget.fallbackSummary.isNotEmpty
        ? widget.fallbackSummary
        : (widget.fallbackDescription.isNotEmpty
              ? widget.fallbackDescription
              : 'Plan summary');
    return PlanSummary(
      goalId: '',
      overview: text,
      phases: const [],
      estimatedDurationDays: null,
    );
  }
}

class _PlanSummaryContent extends StatelessWidget {
  const _PlanSummaryContent({required this.summary, required this.collapsed});

  final PlanSummary summary;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final previewText = _preview(summary.overview);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Plan summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: collapsed
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                previewText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              if (summary.estimatedDurationDays != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Estimated duration: ${summary.estimatedDurationDays} days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.overview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              if (summary.estimatedDurationDays != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Estimated duration: ${summary.estimatedDurationDays} days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final phase in summary.phases) ...[
                _PlanPhaseTile(phase: phase),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (collapsed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _preview(String text) {
    if (text.isEmpty) return 'Plan summary';
    return text;
  }
}

class _PlanPhaseTile extends StatelessWidget {
  const _PlanPhaseTile({required this.phase});

  final PlanPhase phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phase.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (phase.daysRange != null && phase.daysRange!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phase.daysRange!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(phase.focus, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PlanSummaryContainer extends StatelessWidget {
  const _PlanSummaryContainer({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: child,
        ),
      ),
    );
  }
}
