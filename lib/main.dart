// lib/main.dart
// Bootstraps Treespora by wiring Supabase, theming, and the router.
// Exists to keep configuration in one place for fast onboarding of new devs.
// RELEVANT FILES:lib/app/core/routes.dart,lib/app/core/config/app_config.dart,lib/app/root/startup_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/core/config/app_config.dart';
import 'app/core/routes.dart';
import 'app/core/theme/theme.dart';
import 'app/features/goals/state/active_goal_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.hasSupabaseKeys) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } else {
    AppConfig.debugLogMissingSupabase();
  }

  final themeController = await ThemeController.create();
  final activeGoalController = await ActiveGoalController.create();
  runApp(
    TreesporaApp(
      themeController: themeController,
      activeGoalController: activeGoalController,
    ),
  );
}

class TreesporaApp extends StatelessWidget {
  const TreesporaApp({
    super.key,
    required this.themeController,
    required this.activeGoalController,
  });

  final ThemeController themeController;
  final ActiveGoalController activeGoalController;

  @override
  Widget build(BuildContext context) {
    return ThemeControllerProvider(
      controller: themeController,
      child: ActiveGoalControllerProvider(
        controller: activeGoalController,
        child: AnimatedBuilder(
          animation: themeController,
          builder: (context, _) {
            return MaterialApp(
              title: 'Treespora',
              debugShowCheckedModeBanner: false,
              themeMode: themeController.themeMode,
              theme: lightTheme,
              darkTheme: darkTheme,
              initialRoute: AppRoutes.startup,
              onGenerateRoute: AppRoutes.onGenerateRoute,
              onUnknownRoute: AppRoutes.onUnknownRoute,
            );
          },
        ),
      ),
    );
  }
}
