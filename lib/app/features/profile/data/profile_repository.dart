// lib/app/features/profile/data/profile_repository.dart
// Provides read/write access to the Supabase profile table for user metadata.
// Exists so age, birth date, and language settings stay consistent across goals and plans.
// RELEVANT FILES:lib/app/features/goals/data/goal_repository.dart,lib/app/features/onboarding/state/onboarding_state.dart,lib/app/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

class ProfileData {
  const ProfileData({
    this.age,
    this.birthDate,
    this.languageCode,
    this.gender,
    this.firstName,
    this.lastName,
    this.goalsCreatedCount = 0,
  });

  final int? age;
  final DateTime? birthDate;
  final String? languageCode;
  final String? gender;
  final String? firstName;
  final String? lastName;
  final int goalsCreatedCount;

  static const List<String> allowedLanguages = [
    'en',
    'es',
    'zh',
    'hi',
    'ar',
    'ro',
  ];

  ProfileData copyWith({
    int? age,
    DateTime? birthDate,
    String? languageCode,
    String? gender,
    String? firstName,
    String? lastName,
    int? goalsCreatedCount,
  }) {
    return ProfileData(
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      languageCode: languageCode ?? this.languageCode,
      gender: gender ?? this.gender,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      goalsCreatedCount: goalsCreatedCount ?? this.goalsCreatedCount,
    );
  }

  Map<String, dynamic> toSupabasePayload(String userId) {
    final normalizedLanguage = _normalizeLanguage(languageCode);
    return <String, dynamic>{
      'id': userId,
      if (age != null) 'age': age,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
      if (normalizedLanguage != null) 'language_code': normalizedLanguage,
      if (gender != null && gender!.trim().isNotEmpty) 'gender': gender,
      if (firstName != null && firstName!.trim().isNotEmpty)
        'first_name': firstName,
      if (lastName != null && lastName!.trim().isNotEmpty)
        'last_name': lastName,
      'goals_created_count': goalsCreatedCount,
    };
  }

  String? toContextString() {
    final parts = <String>[];
    if (age != null) {
      parts.add('age: $age');
    }
    if (birthDate != null) {
      parts.add('birth_date: ${birthDate!.toIso8601String()}');
    }
    if (languageCode != null && _normalizeLanguage(languageCode) != null) {
      parts.add('language: ${languageCode!.trim()}');
    }
    if (gender != null && gender!.trim().isNotEmpty) {
      parts.add('gender: ${gender!.trim()}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(', ');
  }

  static ProfileData fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return const ProfileData();
    }
    DateTime? birthDate;
    final rawBirth = raw['birth_date'];
    if (rawBirth is String && rawBirth.isNotEmpty) {
      try {
        birthDate = DateTime.parse(rawBirth);
      } catch (_) {
        birthDate = null;
      }
    }
    // Parse age as int (can come as int or String from Supabase)
    int? parsedAge;
    final rawAge = raw['age'];
    if (rawAge is int) {
      parsedAge = rawAge;
    } else if (rawAge is String && rawAge.isNotEmpty) {
      parsedAge = int.tryParse(rawAge);
    }
    final rawLanguage = raw['language_code'] as String?;
    final rawGender = raw['gender'] as String?;
    final rawFirstName = raw['first_name'] as String?;
    final rawLastName = raw['last_name'] as String?;
    // Parse goals_created_count
    int goalsCount = 0;
    final rawGoalsCount = raw['goals_created_count'];
    if (rawGoalsCount is int) {
      goalsCount = rawGoalsCount;
    } else if (rawGoalsCount is String && rawGoalsCount.isNotEmpty) {
      goalsCount = int.tryParse(rawGoalsCount) ?? 0;
    }
    return ProfileData(
      age: parsedAge,
      birthDate: birthDate,
      languageCode: _normalizeLanguage(rawLanguage),
      gender: rawGender,
      firstName: rawFirstName,
      lastName: rawLastName,
      goalsCreatedCount: goalsCount,
    );
  }

  static String? _normalizeLanguage(String? code) {
    if (code == null) {
      return null;
    }
    final normalized = code.trim().toLowerCase();
    if (allowedLanguages.contains(normalized)) {
      return normalized;
    }
    return null;
  }
}

class ProfileRepository {
  ProfileRepository._(this._client);

  final SupabaseClient? _client;

  static ProfileRepository? _instance;
  static const String _tableName = 'profiles';

  static ProfileRepository get instance {
    _instance ??= ProfileRepository._(_resolveClient());
    return _instance!;
  }

  static SupabaseClient? _resolveClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _configured => AppConfig.hasSupabaseKeys && _client != null;

  Future<ProfileData?> fetchProfile() async {
    if (!_configured) {
      return null;
    }
    final userId = _client?.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    try {
      final response = await _client!
          .from(_tableName)
          .select()
          .eq('id', userId)
          .limit(1)
          .maybeSingle();
      if (response is Map<String, dynamic>) {
        return ProfileData.fromMap(response);
      }
    } catch (error) {
      debugPrint('ProfileRepository.fetchProfile failed: $error');
    }
    return null;
  }

  Future<ProfileData?> upsertProfile(ProfileData data) async {
    if (!_configured) {
      return null;
    }
    final userId = _client?.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final payload = data.toSupabasePayload(userId);
    if (payload.length <= 1) {
      return data;
    }
    try {
      final response = await _client!
          .from(_tableName)
          .upsert(payload)
          .select()
          .maybeSingle();
      if (response is Map<String, dynamic>) {
        return ProfileData.fromMap(response);
      }
    } catch (error) {
      debugPrint('ProfileRepository.upsertProfile failed: $error');
    }
    return data;
  }
}
