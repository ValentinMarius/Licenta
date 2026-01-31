// lib/app/features/home/presentation/widgets/home_week_header.dart
// Shows the current plan week number and day range above the horizontal calendar.
// Exists to keep the journey tab aware of plan cadence without cluttering the calendar widget.
// RELEVANT FILES:lib/app/features/home/presentation/widgets/home_calendar_strip.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart,lib/app/features/goals/data/plan_repository.dart

import 'package:flutter/material.dart';

class HomeWeekHeader extends StatelessWidget {
  const HomeWeekHeader({
    super.key,
    required this.weekIndex,
    required this.startDay,
    required this.endDay,
    required this.totalDays,
  });

  final int weekIndex;
  final int startDay;
  final int endDay;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String rangeLabel = 'Days $startDay–$endDay of $totalDays';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week $weekIndex',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rangeLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
