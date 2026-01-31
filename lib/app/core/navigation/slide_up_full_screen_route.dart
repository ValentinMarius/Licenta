// lib/app/core/navigation/slide_up_full_screen_route.dart
// Custom route that animates pages from bottom to top full-screen.
// Exists so full-screen modals like Profile/Streak can feel native and consistent.
// RELEVANT FILES:lib/app/features/home/root/main_tab_shell.dart,lib/app/features/profile/presentation/screens/profile_screen.dart,lib/app/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';

class SlideUpFullScreenRoute<T> extends PageRouteBuilder<T> {
  SlideUpFullScreenRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          },
          opaque: true,
          barrierDismissible: false,
          maintainState: true,
        );
}
