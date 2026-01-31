// lib/app/features/home/presentation/widgets/home_bottom_nav_bar.dart
// Isolates the bottom navigation styling for the home shell.
// Keeps the main screen lean and allows future reuse/customization.
// RELEVANT FILES:lib/app/features/home/root/main_tab_shell.dart,lib/app/core/theme/app_canvas_background.dart,lib/app/core/routes.dart

import 'package:flutter/material.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final base =
        theme.bottomNavigationBarTheme.backgroundColor ??
        theme.navigationBarTheme.backgroundColor ??
        colorScheme.background;

    return Container(
      decoration: BoxDecoration(
        color: base,
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.10),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _navSpecs.length,
              (index) => Expanded(
                child: _NavButton(
                  spec: _navSpecs[index],
                  isActive: index == currentIndex,
                  onTap: () => onTap(index),
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const List<_NavSpec> _navSpecs = [
  _NavSpec(icon: Icons.flag_outlined, label: 'Tasks'),
  _NavSpec(icon: Icons.home_outlined, label: 'Home'),
  _NavSpec(icon: Icons.eco_outlined, label: 'Forest'),
  _NavSpec(icon: Icons.person_outline_rounded, label: 'Profile'),
];

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.spec,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  final _NavSpec spec;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final activeOpacity = isDark ? 0.10 : 0.08;
    final idleOpacity = isDark ? 0.03 : 0.02;
    final iconBackground = colorScheme.onSurface.withOpacity(
      isActive ? activeOpacity : idleOpacity,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: onTap,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: isActive
                      ? Border.all(
                          color: colorScheme.primary.withOpacity(0.4),
                          width: 1.1,
                        )
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  spec.icon,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
