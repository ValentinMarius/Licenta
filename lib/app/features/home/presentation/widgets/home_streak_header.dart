// lib/app/features/home/presentation/widgets/home_streak_header.dart
// Renders the streak chip and centered title on the Home tab.
// Exists to keep the HomeScreen lean and ready for future data binding.
// RELEVANT FILES:lib/app/features/home/presentation/screens/home_screen.dart,lib/app/features/home/root/main_tab_shell.dart,lib/app/features/home/presentation/widgets/home_bottom_nav_bar.dart

import 'package:flutter/material.dart';

class HomeStreakHeader extends StatelessWidget {
  const HomeStreakHeader({
    super.key,
    required this.streak,
  });

  final StreakSnapshot streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _StreakChip(streak: streak),
        Expanded(
          child: Center(
            child: Text(
              'Treespora',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40, height: 40),
      ],
    );
  }
}

class StreakSnapshot {
  const StreakSnapshot({required this.current, required this.best});

  final int current;
  final int best;
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final StreakSnapshot streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${streak.current} day streak',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Best: ${streak.best}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
