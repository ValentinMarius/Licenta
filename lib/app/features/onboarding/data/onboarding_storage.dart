// lib/app/features/onboarding/data/onboarding_storage.dart
// Handles saving and loading onboarding state plus completion flags.
// Centralizes SharedPreferences access so onboarding remains consistent across launches.
// RELEVANT FILES:lib/app/features/onboarding/state/onboarding_state.dart,lib/app/root/welcome_screen.dart,lib/app/features/onboarding/presentation/screens/source_screen.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../state/onboarding_state.dart';

class OnboardingStorage {
  static const String _stateKey = 'treesporapp_onboarding_state';
  static const String _doneKey = 'treesporapp_onboarding_done';
  static const String _contextKey = 'treesporapp_onboarding_context';

  const OnboardingStorage._();

  static Future<SharedPreferences> _prefs() {
    return SharedPreferences.getInstance();
  }

  static Future<OnboardingState> readState() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_stateKey);
    if (raw == null) {
      return const OnboardingState.initial();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return OnboardingState.fromMap(decoded);
      }
    } catch (_) {
      // Ignore malformed cache and fall back to defaults.
    }
    return const OnboardingState.initial();
  }

  static Future<void> saveState(OnboardingState state) async {
    final prefs = await _prefs();
    await prefs.setString(_stateKey, jsonEncode(state.toMap()));
    await prefs.setString(_contextKey, state.toMergedContext());
  }

  static Future<void> completeOnboarding(OnboardingState state) async {
    final prefs = await _prefs();
    await prefs.setString(_stateKey, jsonEncode(state.toMap()));
    await prefs.setString(_contextKey, state.toMergedContext());
    await prefs.setBool(_doneKey, true);
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await _prefs();
    return prefs.getBool(_doneKey) ?? false;
  }

  static Future<void> ensureOnboardingDoneFlag() async {
    final prefs = await _prefs();
    if (!(prefs.getBool(_doneKey) ?? false)) {
      await prefs.setBool(_doneKey, true);
    }
  }

  static Future<String> readMergedContext() async {
    final prefs = await _prefs();
    final cached = prefs.getString(_contextKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final state = await readState();
    final context = state.toMergedContext();
    await prefs.setString(_contextKey, context);
    return context;
  }
}
