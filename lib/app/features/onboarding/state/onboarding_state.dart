// lib/app/features/onboarding/state/onboarding_state.dart
// Defines the immutable onboarding state snapshot and helpers.
// Keeps onboarding answers consistent and ready for persistence or AI prompts.
// RELEVANT FILES:lib/app/features/onboarding/data/onboarding_storage.dart,lib/app/features/onboarding/presentation/screens/source_screen.dart,lib/app/root/welcome_screen.dart

class OnboardingState {
  static const String skipValue = 'skip';

  final String category;
  final String age;
  final String journeyStage;
  final String timeCommitment;
  final String discoverySource;
  final String language;

  const OnboardingState({
    this.category = skipValue,
    this.age = skipValue,
    this.journeyStage = skipValue,
    this.timeCommitment = skipValue,
    this.discoverySource = skipValue,
    this.language = skipValue,
  });

  const OnboardingState.initial() : this();

  OnboardingState copyWith({
    String? category,
    String? age,
    String? journeyStage,
    String? timeCommitment,
    String? discoverySource,
    String? language,
  }) {
    return OnboardingState(
      category: category ?? this.category,
      age: age ?? this.age,
      journeyStage: journeyStage ?? this.journeyStage,
      timeCommitment: timeCommitment ?? this.timeCommitment,
      discoverySource: discoverySource ?? this.discoverySource,
      language: language ?? this.language,
    );
  }

  Map<String, String> toMap() {
    return {
      'category': category,
      'age': age,
      'journeyStage': journeyStage,
      'timeCommitment': timeCommitment,
      'discoverySource': discoverySource,
      'language': language,
    };
  }

  factory OnboardingState.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return const OnboardingState.initial();
    }
    return OnboardingState(
      category: _stringOrSkip(raw['category']),
      age: _stringOrSkip(raw['age']),
      journeyStage: _stringOrSkip(raw['journeyStage']),
      timeCommitment: _stringOrSkip(raw['timeCommitment']),
      discoverySource: _stringOrSkip(raw['discoverySource']),
      language: _stringOrSkip(raw['language']),
    );
  }

  static String _stringOrSkip(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return skipValue;
  }

  String toMergedContext() {
    final buffer = StringBuffer()
      ..write('category: ${_formatValue(category)}, ')
      ..write('age: ${_formatValue(age)}, ')
      ..write('journey stage: ${_formatValue(journeyStage)}, ')
      ..write('time commitment: ${_formatValue(timeCommitment)}, ')
      ..write('discovery source: ${_formatValue(discoverySource)}, ')
      ..write('language: ${_formatValue(language)}');
    return buffer.toString();
  }

  String _formatValue(String value) {
    return value.isEmpty ? skipValue : value;
  }
}
