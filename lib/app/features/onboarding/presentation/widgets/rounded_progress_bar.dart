import 'package:flutter/material.dart';

/// A rounded progress bar that animates smoothly between values. The widget
/// keeps track of the previous value so that changes, including decreases, are
/// animated visibly.
class RoundedProgressBar extends StatefulWidget {
  final double value;
  final double? startValue;
  final Duration duration;
  final double height;
  final double borderRadius;
  final Color? trackColor;
  final Color? fillColor;

  const RoundedProgressBar({
    super.key,
    required this.value,
    this.startValue,
    this.duration = const Duration(milliseconds: 600),
    this.height = 6,
    this.borderRadius = 12,
    this.trackColor,
    this.fillColor,
  });

  @override
  State<RoundedProgressBar> createState() => _RoundedProgressBarState();
}

class _RoundedProgressBarState extends State<RoundedProgressBar> {
  late double _begin;

  @override
  void initState() {
    super.initState();
    _begin = widget.startValue ?? widget.value;
  }

  @override
  void didUpdateWidget(covariant RoundedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startValue != null &&
        widget.startValue != oldWidget.startValue) {
      _begin = widget.startValue!;
    } else if (widget.value != oldWidget.value) {
      _begin = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trackColor = widget.trackColor ?? colorScheme.surfaceVariant;
    final fillColor = widget.fillColor ?? colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _begin, end: widget.value),
      duration: widget.duration,
      curve: Curves.easeInOut,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: LinearProgressIndicator(
            value: animatedValue,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            minHeight: widget.height,
          ),
        );
      },
    );
  }
}
