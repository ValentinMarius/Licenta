// lib/app/core/config/app_config.dart
// Centralizes runtime configuration coming from Dart defines or env.
// Keeps secrets out of the codebase and visible in a single place.
// RELEVANT FILES:lib/main.dart,lib/app/features/auth/data/auth_repository.dart,lib/app/root/startup_screen.dart,lib/app/features/goals/data/goal_repository.dart

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static bool get hasSupabaseKeys =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void debugLogMissingSupabase() {
    if (!hasSupabaseKeys) {
      debugPrint(
        'Supabase keys are missing. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
  }
}
