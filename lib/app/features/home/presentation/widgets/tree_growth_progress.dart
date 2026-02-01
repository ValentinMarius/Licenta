// lib/app/features/home/presentation/widgets/tree_growth_progress.dart
// Shows the growing tree image and a 5-step segmented progress bar for Home.
// Exists to visually map plan progress to 5 fixed growth stages (1 image per stage).
// RELEVANT FILES:lib/app/features/home/presentation/screens/home_screen.dart,lib/app/features/tasks/state/task_progress_store.dart,pubspec.yaml

import 'package:flutter/material.dart';

class TreeGrowthProgress extends StatelessWidget {
  const TreeGrowthProgress({
    super.key,
    required this.progress,
    this.imageHeight = 160,
    this.barHeight = 10,
  });

  final double progress;
  final double imageHeight;
  final double barHeight;

  static const List<String> _treeStageAssets = [
    'lib/app/features/home/presentation/widgets/image.png',
    'lib/app/features/home/presentation/widgets/image-1.png',
    'lib/app/features/home/presentation/widgets/image-2.png',
    'lib/app/features/home/presentation/widgets/image-3.png',
    'lib/app/features/home/presentation/widgets/image-4.png',
  ];

  int _stageIndexFor(double value) {
    final clamped = value.clamp(0.0, 1.0);
    return ((clamped * 100) / 20).floor().clamp(0, _treeStageAssets.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final stageIndex = _stageIndexFor(progress);
    final asset = _treeStageAssets[stageIndex];

    return Column(
      children: [
        SizedBox(
          height: imageHeight,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        _FiveStepProgressBar(
          progress: progress,
          height: barHeight,
        ),
      ],
    );
  }
}

class _FiveStepProgressBar extends StatelessWidget {
  const _FiveStepProgressBar({
    required this.progress,
    required this.height,
  });

  final double progress;
  final double height;

  static const int _segments = 5;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final normalized = progress.clamp(0.0, 1.0);
    final overall = normalized * _segments;

    return Row(
      children: [
        for (var i = 0; i < _segments; i++) ...[
          Expanded(
            child: _SegmentBar(
              fill: (overall - i).clamp(0.0, 1.0),
              height: height,
              filledColor: scheme.primary,
              backgroundColor: scheme.surface,
              borderColor: scheme.outlineVariant,
              roundLeft: i == 0,
              roundRight: i == _segments - 1,
            ),
          ),
          if (i != _segments - 1) const SizedBox(width: _gap),
        ],
      ],
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.fill,
    required this.height,
    required this.filledColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.roundLeft,
    required this.roundRight,
  });

  final double fill;
  final double height;
  final Color filledColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool roundLeft;
  final bool roundRight;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(height / 2);
    final borderRadius = BorderRadius.horizontal(
      left: roundLeft ? radius : Radius.zero,
      right: roundRight ? radius : Radius.zero,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fill.clamp(0.0, 1.0),
          child: ColoredBox(color: filledColor),
        ),
      ),
    );
  }
}

