// lib/app/features/home/presentation/widgets/home_calendar_strip.dart
// Displays the swipeable minimalist horizontal calendar with progress pills and selection.
// Exists to keep the journey and home surfaces uncluttered while showing progress states per day.
// RELEVANT FILES:lib/app/features/home/presentation/screens/journey_goal_tab.dart,lib/app/features/home/presentation/screens/home_screen.dart,lib/app/features/home/root/main_tab_shell.dart

import 'package:flutter/material.dart';

class HomeCalendarStrip extends StatefulWidget {
  const HomeCalendarStrip({
    super.key,
    required this.days,
    required this.selectedDayIndex,
    required this.onDaySelected,
    this.onWeekChanged,
  });

  final List<HomeCalendarDay> days;
  final int selectedDayIndex;
  final ValueChanged<HomeCalendarDay> onDaySelected;
  final ValueChanged<int>? onWeekChanged;

  @override
  State<HomeCalendarStrip> createState() => _HomeCalendarStripState();
}

class _HomeCalendarStripState extends State<HomeCalendarStrip> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _deriveInitialPage();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _chunkWeeks(widget.days);
    if (weeks.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 110,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: weeks.length,
        onPageChanged: (index) {
          _currentPage = index;
          widget.onWeekChanged?.call(index + 1);
        },
        itemBuilder: (context, index) {
          final baseIndex = index * 7;
          final selectedIndex = widget.selectedDayIndex;
          return _CalendarWeekRow(
            days: weeks[index],
            selectedDayIndex: selectedIndex,
            baseIndex: baseIndex,
            onTap: widget.onDaySelected,
          );
        },
      ),
    );
  }

  // Breaks the source list into 7-day slices so users can swipe week by week.
  List<List<HomeCalendarDay>> _chunkWeeks(List<HomeCalendarDay> source) {
    if (source.isEmpty) {
      return const <List<HomeCalendarDay>>[];
    }
    final weeks = <List<HomeCalendarDay>>[];
    for (var i = 0; i < source.length; i += 7) {
      final end = (i + 7).clamp(0, source.length).toInt();
      weeks.add(source.sublist(i, end));
    }
    return weeks;
  }

  int _deriveInitialPage() {
    if (widget.days.isEmpty) return 0;
    final selectedIndex = widget.selectedDayIndex;
    if (selectedIndex <= 0) return 0;
    return (selectedIndex ~/ 7);
  }
}

class HomeCalendarDay {
  const HomeCalendarDay({
    required this.label,
    required this.planDayIndex,
    required this.dayNumber,
    required this.status,
    required this.date,
    this.isToday = false,
  });

  final String label;
  final int planDayIndex;
  final int dayNumber;
  final HomeDayStatus status;
  final DateTime date;
  final bool isToday;
}

enum HomeDayStatus { completed, partial, missed, upcoming }

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    required this.days,
    required this.selectedDayIndex,
    required this.baseIndex,
    required this.onTap,
  });

  final List<HomeCalendarDay> days;
  final int selectedDayIndex;
  final int baseIndex;
  final ValueChanged<HomeCalendarDay> onTap;

  @override
  Widget build(BuildContext context) {
    final paddedDays = List<HomeCalendarDay?>.of(days);
    while (paddedDays.length < 7) {
      paddedDays.add(null);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paddedDays.length; i++) ...[
            Expanded(
              child: paddedDays[i] == null
                  ? const SizedBox()
                  : _CalendarDayTile(
                      day: paddedDays[i]!,
                      isSelected: (baseIndex + i) == selectedDayIndex,
                      onTap: onTap,
                    ),
            ),
            if (i != paddedDays.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final HomeCalendarDay day;
  final bool isSelected;
  final ValueChanged<HomeCalendarDay> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isFuture = !day.isToday && day.status == HomeDayStatus.upcoming;
    final bool isPast = !day.isToday && day.status != HomeDayStatus.upcoming;
    final Color baseBorder = _statusColor(day.status, scheme);
    final Color borderColor = (isPast ? _dimmedColor(baseBorder) : baseBorder)
        .withOpacity(isFuture ? 0.4 : 1.0);
    final Color textColor = isSelected
        ? scheme.onPrimary
        : isFuture
            ? scheme.onSurface.withOpacity(0.35)
            : Colors.white;
    final double borderWidth = isFuture ? 0 : (isSelected ? 2 : 1.5);
    final FontWeight labelWeight =
        day.isToday ? FontWeight.w700 : FontWeight.w500;
    final Color fillColor = isSelected
        ? scheme.primary
        : isFuture
            ? Colors.transparent
            : borderColor.withOpacity(0.12);

    return SizedBox(
      height: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onTap(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: borderWidth),
                color: fillColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: labelWeight,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.dayNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(HomeDayStatus status, ColorScheme scheme) {
  switch (status) {
    case HomeDayStatus.completed:
      return const Color(0xFF2F7A5B);
    case HomeDayStatus.partial:
      return const Color(0xFFF4C254);
    case HomeDayStatus.missed:
      return const Color(0xFFD84B4B);
    case HomeDayStatus.upcoming:
      return const Color(0xFF555555);
  }
}

Color _dimmedColor(Color color) {
  // Past days keep their hue but appear subdued to signal history.
  return Color.alphaBlend(Colors.black.withOpacity(0.35), color);
}
