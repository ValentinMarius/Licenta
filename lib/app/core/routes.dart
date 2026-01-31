// lib/app/core/routes.dart
// Centralizes every named route and the onboarding transition builder.
// Ensures onboarding screens all share the same Cupertino slide animation.
// RELEVANT FILES:lib/app/root/welcome_screen.dart,lib/app/features/onboarding/presentation/screens/onboarding_screen.dart,lib/main.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:treespora/app/features/home/root/main_tab_shell.dart';
import 'package:treespora/app/features/onboarding/presentation/screens/journey_stage_screen.dart';
import 'package:treespora/app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:treespora/app/features/onboarding/presentation/screens/source_screen.dart';
import 'package:treespora/app/features/onboarding/presentation/screens/time_commitment_screen.dart';
import 'package:treespora/app/root/startup_screen.dart';
import 'package:treespora/app/root/welcome_screen.dart';

/// Toate rutele numite ale aplicației.
/// Adaugi aici când mai creezi ecrane noi (progress, forest, login etc.).
class AppRoutes {
  // Entry points
  static const String startup = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';

  static const String journeyStage = '/journey-stage';
  static const String timeCommitment = '/time-commitment';
  static const String source = '/source';
  static const String home = '/home';

  static final Map<String, WidgetBuilder> _onboardingRoutes = {
    onboarding: (_) => const OnboardingScreen(),
    journeyStage: (_) => const JourneyStageScreen(),
    timeCommitment: (_) => const TimeCommitmentScreen(),
    source: (_) => const SourceScreen(),
  };

  static final Map<String, WidgetBuilder> _routes = {
    startup: (_) => const StartupScreen(),
    welcome: (_) => const WelcomeScreen(),
    home: (_) => const MainTabShell(),
    ..._onboardingRoutes,
  };

  /// Creates a slide transition used throughout onboarding.
  static PageRouteBuilder<T> onboardingRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: true,
          child: child,
        );
      },
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = _routes[settings.name];
    if (builder != null) {
      if (_onboardingRoutes.containsKey(settings.name)) {
        return onboardingRoute(builder: builder, settings: settings);
      }

      return MaterialPageRoute(builder: builder, settings: settings);
    }

    return onUnknownRoute(settings);
  }

  /// Fallback prietenos dacă mergi pe o rută care nu există încă.
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(child: Text('Ruta necunoscută: ${settings.name}')),
      ),
    );
  }
}
