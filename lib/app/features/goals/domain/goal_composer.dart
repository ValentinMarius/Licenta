// lib/app/features/goals/domain/goal_composer.dart
// Transforms onboarding answers and user input into a final goal summary.
// Keeps the formatting deterministic until AI planning is introduced.
// RELEVANT FILES:lib/app/features/goals/data/goal_repository.dart,lib/app/features/onboarding/data/onboarding_storage.dart,lib/app/features/home/root/main_tab_shell.dart

class GoalComposer {
  const GoalComposer._();

  static String compose({
    required String userContext,
    required String userDescription,
  }) {
    final trimmedDescription = userDescription.trim();
    final buffer = StringBuffer()
      ..write('User context: ')
      ..writeln(userContext.trim())
      ..writeln()
      ..write('User goal description: ')
      ..write(trimmedDescription);
    return buffer.toString().trim();
  }

  static String deriveTitle(String userDescription) {
    final trimmed = userDescription.trim();
    if (trimmed.isEmpty) {
      return 'New goal';
    }

    final firstBoundary = _findFirstBoundary(trimmed);
    final rawTitle =
        firstBoundary != null ? trimmed.substring(0, firstBoundary) : trimmed;
    const maxLength = 60;
    if (rawTitle.length <= maxLength) {
      return rawTitle;
    }
    return '${rawTitle.substring(0, maxLength).trim()}…';
  }

  static int? _findFirstBoundary(String text) {
    final boundaries = ['.', '!', '?', '\n'];
    final indexes = boundaries
        .map((separator) => text.indexOf(separator))
        .where((index) => index >= 0)
        .toList();
    if (indexes.isEmpty) {
      return null;
    }
    indexes.sort();
    return indexes.first;
  }
}
