// lib/app/root/startup_screen.dart
// Lightweight splash that decides which route to open on app launch.
// Ensures onboarding/login rules run before any UI flashes on screen.
// RELEVANT FILES:lib/app/features/onboarding/data/onboarding_storage.dart,lib/app/features/auth/data/auth_repository.dart,lib/app/core/routes.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/core/theme/app_canvas_background.dart';
import 'package:treespora/app/core/routes.dart';
import 'package:treespora/app/features/auth/data/auth_repository.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideNextRoute();
    });
  }

  Future<void> _decideNextRoute() async {
    final authRepo = AuthRepository.instance;

    // Only go to Home if user has an active session (is logged in).
    // Otherwise, always show Welcome screen.
    final targetRoute = authRepo.hasActiveSession
        ? AppRoutes.home
        : AppRoutes.welcome;

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return AppCanvasBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
