// lib/app/features/auth/data/auth_repository.dart
// Wraps Supabase auth calls with lightweight error handling.
// Keeps the UI widgets clean and focused on presentation logic.
// RELEVANT FILES:lib/app/core/config/app_config.dart,lib/app/features/auth/presentation/widgets/login_form.dart,lib/app/features/auth/presentation/widgets/signup_form.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository._(this._client);

  final SupabaseClient? _client;

  static AuthRepository? _instance;

  static AuthRepository get instance {
    _instance ??= AuthRepository._(_resolveClient());
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

  bool get hasActiveSession =>
      _configured && _client!.auth.currentSession != null;

  User? get currentUser => _client?.auth.currentUser;

  String? get currentUserEmail => _client?.auth.currentUser?.email;

  Future<void> signIn({required String email, required String password}) async {
    _ensureConfigured();
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw const AuthFlowException('Check your inbox to finish signing in.');
      }
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (_) {
      throw const AuthFlowException(
        'We could not sign you in. Please try again.',
      );
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? gender,
  }) async {
    _ensureConfigured();
    try {
      // Build user metadata with separate first_name, last_name, and gender
      final Map<String, dynamic> userData = {};
      if (firstName != null && firstName.isNotEmpty) {
        userData['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        userData['last_name'] = lastName;
      }
      if (gender != null && gender.isNotEmpty) {
        userData['gender'] = gender;
      }
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: userData.isNotEmpty ? userData : null,
      );
      return response.session == null;
    } on AuthException catch (error) {
      throw AuthFlowException(error.message);
    } catch (_) {
      throw const AuthFlowException(
        'We could not create your account. Please try later.',
      );
    }
  }

  Future<void> signOut() async {
    if (!_configured) {
      return;
    }
    await _client?.auth.signOut();
  }

  /// Deletes the current user's account and all associated data.
  /// Calls Edge Function to delete from auth.users (requires admin privileges).
  Future<void> deleteAccount() async {
    _ensureConfigured();
    final session = _client!.auth.currentSession;
    if (session == null) {
      throw const AuthFlowException('No active session.');
    }

    try {
      // Delete from profiles table first (cascade will handle goals, plans, tasks)
      await _client.from('profiles').delete().eq('id', session.user.id);

      // Call Edge Function to delete from auth.users
      final response = await _client.functions.invoke(
        'delete-user',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Failed to delete account';
        throw AuthFlowException(error.toString());
      }
    } catch (e) {
      if (e is AuthFlowException) rethrow;
      throw AuthFlowException('Failed to delete account: $e');
    }
  }

  void _ensureConfigured() {
    if (!_configured) {
      throw const AuthFlowException(
        'Supabase keys are missing. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }
}
