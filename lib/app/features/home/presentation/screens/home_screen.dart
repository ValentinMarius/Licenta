// lib/app/features/home/presentation/screens/home_screen.dart
// Presents the minimal Treespora home tab with streak header and placeholder.
// Exists to preview upcoming goal progress while other tabs handle heavy logic.
// RELEVANT FILES:lib/app/features/home/root/main_tab_shell.dart,lib/app/features/home/presentation/widgets/home_streak_header.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/home/presentation/widgets/home_streak_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  static const StreakSnapshot _streakSample =
      StreakSnapshot(current: 5, best: 14);
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeStreakHeader(
            streak: _streakSample,
          ),
          const SizedBox(height: 48),
          const _HomePlaceholder(),
        ],
      ),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            'Goal progress – coming soon',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We are crafting your forest view. Stay tuned.',
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
