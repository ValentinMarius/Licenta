// lib/app/features/goals/data/goal_repository.dart
// Persists goals to Supabase after merging onboarding context with the user note.
// Keeps storage and formatting concerns separate from the UI widgets.
// RELEVANT FILES:lib/app/features/goals/domain/goal_composer.dart,lib/app/features/onboarding/data/onboarding_storage.dart,lib/app/features/home/root/main_tab_shell.dart,lib/app/features/goals/domain/plan_summary.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:treespora/app/core/config/app_config.dart';
import 'package:treespora/app/features/onboarding/data/onboarding_storage.dart';
import 'package:treespora/app/features/onboarding/state/onboarding_state.dart';
import 'package:treespora/app/features/profile/data/profile_repository.dart';
import '../domain/goal_composer.dart';
import '../domain/goal_completion_stats.dart';
import '../domain/goal_summary.dart';
import '../domain/plan_summary.dart';

class GoalCreationException implements Exception {
  const GoalCreationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GoalFetchException implements Exception {
  const GoalFetchException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GoalRepository {
  GoalRepository._(this._client);

  static const String _invalidGoalMessage =
      'Nu se poate genera un plan pentru obiectivul ales deoarece nu respecta termenii si conditiile.';

  static final List<RegExp> _invalidGoalPatterns = [
    RegExp(
      r'\b(reteta|rețeta|recipe|gluma|glum[aă]|joke|poanta|poant[aă])\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(how\s+to\s+bury|how\s+to\s+cook|cum\s+sa\s+ingrop|cum\s+sa\s+gat(e|i)sti)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(ingropa\s+o\s+g(ai|a)na|bury\s+(a\s+)?chicken)\b',
      caseSensitive: false,
    ),
  ];

  final SupabaseClient? _client;

  static GoalRepository? _instance;

  static GoalRepository get instance {
    _instance ??= GoalRepository._(_resolveClient());
    return _instance!;
  }

  static SupabaseClient? _resolveClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _planSummaryCacheKey(String goalId) {
    return 'plan_summary_$goalId';
  }

  Future<PlanSummary?> _readCachedPlanSummary(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planSummaryCacheKey(goalId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PlanSummary.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedPlanSummary(String goalId, String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planSummaryCacheKey(goalId), body);
  }

  static String? validateGoalInput(String userInput) {
    final trimmed = userInput.trim();
    if (trimmed.length < 6) {
      return _invalidGoalMessage;
    }

    final normalized = trimmed.toLowerCase();
    for (final pattern in _invalidGoalPatterns) {
      if (pattern.hasMatch(normalized)) {
        return _invalidGoalMessage;
      }
    }

    return null;
  }

  Future<String> createGoal({
    required String userInput,
    required String startDateIso,
  }) async {
    final validationMessage = validateGoalInput(userInput);
    if (validationMessage != null) {
      throw GoalCreationException(validationMessage);
    }

    final supabase = _client;
    if (supabase == null) {
      throw const GoalCreationException('Please try again later.');
    }

    final trimmed = userInput.trim();
    if (trimmed.isEmpty) {
      throw const GoalCreationException(
        'Please describe your goal before saving it.',
      );
    }

    final normalizedStart = startDateIso.trim();
    if (normalizedStart.isEmpty) {
      throw const GoalCreationException(
        'Please pick when you want your plan to start.',
      );
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const GoalCreationException('Please sign in to save goals.');
    }

    // Get profile and check goals counter
    final profileRepo = ProfileRepository.instance;
    final profile = await profileRepo.fetchProfile() ?? const ProfileData();
    final isFirstGoal = profile.goalsCreatedCount == 0;

    final onboardingState = await OnboardingStorage.readState();
    final onboardingContext = onboardingState.toMergedContext();
    final onboardingLanguage =
        onboardingState.language == OnboardingState.skipValue
        ? null
        : onboardingState.language;
    final languageCode =
        profile.languageCode ??
        onboardingLanguage ??
        ProfileData.allowedLanguages.first;
    final profileContext =
        profile.toContextString() ?? 'language: $languageCode';

    // For first goal, save onboarding language to profile and set counter
    if (isFirstGoal) {
      final profileToSave = profile.copyWith(
        languageCode: languageCode,
        goalsCreatedCount: 1,
      );
      await profileRepo.upsertProfile(profileToSave);
    } else {
      // Increment goals counter for subsequent goals
      final profileToSave = profile.copyWith(
        goalsCreatedCount: profile.goalsCreatedCount + 1,
      );
      await profileRepo.upsertProfile(profileToSave);
    }

    final description = GoalComposer.compose(
      userContext: isFirstGoal ? onboardingContext : profileContext,
      userDescription: trimmed,
    );
    final title = GoalComposer.deriveTitle(trimmed);
    final startDate = _parseIsoDateOnly(normalizedStart);
    if (startDate == null) {
      throw const GoalCreationException(
        'Invalid start date. Please try again.',
      );
    }
    final targetDate = _deriveTargetDateFromInput(
      userInput,
      startDate: startDate,
    );

    try {
      final response = await supabase
          .from('goals')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'difficulty_level': 'MEDIUM',
            'start_date': normalizedStart,
            'target_date': targetDate != null
                ? _formatIsoDateOnly(targetDate)
                : null,
          })
          .select('id')
          .single();
      final goalId = response['id'] as String?;
      if (goalId == null || goalId.isEmpty) {
        throw const GoalCreationException(
          'Goal saved but an id was not returned. Please retry.',
        );
      }
      return goalId;
    } on PostgrestException catch (error) {
      throw GoalCreationException(error.message);
    } catch (_) {
      throw const GoalCreationException(
        'We could not save your goal. Please try again.',
      );
    }
  }

  DateTime? _deriveTargetDateFromInput(
    String userInput, {
    required DateTime startDate,
  }) {
    final match = RegExp(
      r'Preferred completion:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(userInput);
    if (match == null) {
      return null;
    }
    final raw = match.group(1)?.trim();
    if (raw == null ||
        raw.isEmpty ||
        raw.toLowerCase().contains('let ai decide')) {
      return null;
    }
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return null;
    }
    final amount = double.tryParse(parts.first);
    if (amount == null || amount <= 0) {
      return null;
    }
    final unit = parts.length > 1 ? parts[1].toLowerCase() : 'days';
    int multiplier;
    if (unit.startsWith('week')) {
      multiplier = 7;
    } else if (unit.startsWith('month')) {
      multiplier = 30;
    } else {
      multiplier = 1;
    }
    final totalDays = (amount * multiplier).round().clamp(1, 365);
    // Target date is inclusive, so subtract one day to keep the duration exact.
    final offsetDays = totalDays > 0 ? totalDays - 1 : 0;
    final baseDate = DateTime(startDate.year, startDate.month, startDate.day);
    return baseDate.add(Duration(days: offsetDays));
  }

  DateTime? _parseIsoDateOnly(String value) {
    final trimmed = value.trim();
    final parts = trimmed.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _formatIsoDateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _parseDateValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  Future<List<GoalSummary>> fetchGoalsForCurrentUser() async {
    final supabase = _client;
    final userId = supabase?.auth.currentUser?.id;
    if (supabase == null || userId == null) {
      return const [];
    }

    try {
      final response = await supabase
          .from('goals')
          .select('id,title,created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response
          .whereType<Map<String, dynamic>>()
          .map(GoalSummary.fromMap)
          .toList();
    } on PostgrestException catch (error) {
      throw GoalFetchException(error.message);
    } catch (error) {
      debugPrint('GoalRepository.fetchGoalsForCurrentUser failed: $error');
      throw const GoalFetchException(
        'We could not load your goals. Please pull to refresh.',
      );
    }
  }

  Future<GoalCompletionStats> fetchCompletedGoalStats() async {
    final supabase = _client;
    final userId = supabase?.auth.currentUser?.id;
    if (supabase == null || userId == null) {
      return GoalCompletionStats.empty;
    }

    try {
      final response = await supabase
          .from('goals')
          .select('start_date,target_date,completed_at')
          .eq('user_id', userId)
          .not('completed_at', 'is', null);

      var total = 0;
      var in7 = 0;
      var in8To31 = 0;
      var in32To365 = 0;

      for (final row in response.whereType<Map<String, dynamic>>()) {
        final start = _parseDateValue(row['start_date']);
        final target = _parseDateValue(row['target_date']);
        if (start == null || target == null) {
          continue;
        }
        final durationDays = target.difference(start).inDays + 1;
        if (durationDays <= 0) {
          continue;
        }
        total += 1;
        if (durationDays <= 7) {
          in7 += 1;
        } else if (durationDays <= 31) {
          in8To31 += 1;
        } else {
          in32To365 += 1;
        }
      }

      return GoalCompletionStats(
        totalCompleted: total,
        completedIn7Days: in7,
        completedIn8To31Days: in8To31,
        completedIn32To365Days: in32To365,
      );
    } catch (error) {
      debugPrint('GoalRepository.fetchCompletedGoalStats failed: $error');
      return GoalCompletionStats.empty;
    }
  }

  Future<void> markGoalCompleted(String goalId) async {
    final supabase = _client;
    if (supabase == null || goalId.isEmpty) {
      return;
    }
    try {
      final existing = await supabase
          .from('goals')
          .select('completed_at')
          .eq('id', goalId)
          .maybeSingle();
      final completedAt = _parseDateValue(existing?['completed_at']);
      if (completedAt != null) {
        return;
      }
      await supabase
          .from('goals')
          .update({'completed_at': DateTime.now().toIso8601String()})
          .eq('id', goalId);
    } catch (error) {
      debugPrint('GoalRepository.markGoalCompleted failed: $error');
    }
  }

  Future<PlanSummary?> fetchPlanSummary(String goalId) async {
    if (goalId.isEmpty) {
      debugPrint('GoalRepository.fetchPlanSummary: goal id is missing.');
      return null;
    }
    final baseUrl = AppConfig.apiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      debugPrint(
        'GoalRepository.fetchPlanSummary: API base URL missing. '
        'Provide API_BASE_URL via --dart-define.',
      );
      return null;
    }
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBaseUrl/v1/goals/$goalId/plan/summary');
    final cached = await _readCachedPlanSummary(goalId);
    if (cached != null) {
      return cached;
    }
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        await _writeCachedPlanSummary(goalId, response.body);
        return PlanSummary.fromJson(decoded);
      }
      debugPrint(
        'GoalRepository.fetchPlanSummary non-200 '
        '(${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (error) {
      debugPrint('GoalRepository.fetchPlanSummary failed: $error');
      return null;
    }
  }
}
