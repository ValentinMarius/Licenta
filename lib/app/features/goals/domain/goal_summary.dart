// lib/app/features/goals/domain/goal_summary.dart
// Tiny DTO representing a goal row fetched from Supabase.
// Exists so Home/Profile UIs can avoid juggling raw maps.
// RELEVANT FILES:lib/app/features/goals/data/goal_repository.dart,lib/app/features/home/presentation/screens/home_screen.dart,lib/app/features/profile/presentation/screens/profile_tab.dart

class GoalSummary {
  const GoalSummary({
    required this.id,
    required this.title,
    this.createdAt,
  });

  final String id;
  final String title;
  final DateTime? createdAt;

  factory GoalSummary.fromMap(Map<String, dynamic> map) {
    final created = map['created_at'];
    return GoalSummary(
      id: map['id'] as String,
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? (map['title'] as String).trim()
          : 'Untitled goal',
      createdAt:
          created is String ? DateTime.tryParse(created) : created as DateTime?,
    );
  }
}
