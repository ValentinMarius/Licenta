// lib/app/features/profile/data/deletion_feedback_repository.dart
// Handles saving account deletion feedback to Supabase.
// Called before deleting the user account to preserve feedback data.
// RELEVANT FILES:lib/app/features/profile/presentation/screens/delete_account_screen.dart,lib/app/features/auth/data/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for saving account deletion feedback before hard delete.
class DeletionFeedbackRepository {
  DeletionFeedbackRepository._();

  static final DeletionFeedbackRepository instance =
      DeletionFeedbackRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Saves the deletion feedback before the account is deleted.
  /// [reasons] is a list of selected reason strings.
  Future<void> saveFeedback({
    required String userId,
    required String? userEmail,
    required List<String> reasons,
  }) async {
    await _client.from('account_deletion_feedback').insert({
      'user_id': userId,
      'user_email': userEmail,
      'reasons': reasons,
    });
  }
}
