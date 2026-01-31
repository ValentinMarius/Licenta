// lib/app/core/theme/app_canvas_background.dart
// Provides the shared app "canvas" background behind full-screen pages.
// Exists to keep a consistent, branded backdrop without repeating code per screen.
// RELEVANT FILES:lib/app/core/theme/theme.dart,lib/app/root/welcome_screen.dart,lib/app/features/home/root/main_tab_shell.dart

import 'package:flutter/material.dart';

class AppCanvasBackground extends StatelessWidget {
  const AppCanvasBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final base = colorScheme.background;

    return ColoredBox(color: base, child: child);
  }
}
