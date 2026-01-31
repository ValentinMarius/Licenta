// lib/app/features/goals/state/active_goal_controller.dart
// Holds the active goal id and syncs it with Supabase for Home/Profile consumers.
// Exists so both the Home and Profile tabs can stay dumb and rely on one notifier.
// RELEVANT FILES:lib/main.dart,lib/app/features/home/presentation/screens/home_screen.dart,lib/app/features/profile/presentation/screens/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActiveGoalException implements Exception {
  const ActiveGoalException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ActiveGoalController extends ChangeNotifier {
  ActiveGoalController._(this._client);

  final SupabaseClient? _client;
  String? _activeGoalId;

  String? get activeGoalId => _activeGoalId;

  static Future<ActiveGoalController> create() async {
    final controller = ActiveGoalController._(_resolveClient());
    await controller.loadActiveGoal();
    return controller;
  }

  static SupabaseClient? _resolveClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadActiveGoal() async {
    final supabase = _client;
    final userId = supabase?.auth.currentUser?.id;
    if (supabase == null || userId == null) {
      _setLocalActiveGoal(null);
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('active_goal_id')
          .eq('id', userId)
          .maybeSingle();
      final dbGoalId = _readGoalId(profile?['active_goal_id']);
      if (dbGoalId != null) {
        _setLocalActiveGoal(dbGoalId);
        return;
      }

      final fallbackGoal = await supabase
          .from('goals')
          .select('id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final fallbackGoalId = _readGoalId(fallbackGoal?['id']);
      if (fallbackGoalId != null) {
        await supabase
            .from('profiles')
            .update({'active_goal_id': fallbackGoalId})
            .eq('id', userId);
      }
      _setLocalActiveGoal(fallbackGoalId);
    } catch (error) {
      debugPrint('ActiveGoalController.loadActiveGoal failed: $error');
    }
  }

  Future<void> setActiveGoal(String goalId) async {
    if (goalId.isEmpty || goalId == _activeGoalId) {
      return;
    }

    final supabase = _client;
    final userId = supabase?.auth.currentUser?.id;
    if (supabase == null || userId == null) {
      throw const ActiveGoalException('Please sign in to pick an active goal.');
    }

    try {
      await supabase
          .from('profiles')
          .update({'active_goal_id': goalId})
          .eq('id', userId);
      _setLocalActiveGoal(goalId);
    } on PostgrestException catch (error) {
      throw ActiveGoalException(error.message);
    } catch (_) {
      throw const ActiveGoalException(
        'We could not update your active goal. Please try again.',
      );
    }
  }

  void clearActiveGoal() {
    _setLocalActiveGoal(null);
  }

  void _setLocalActiveGoal(String? goalId) {
    if (_activeGoalId == goalId) {
      return;
    }
    _activeGoalId = goalId;
    notifyListeners();
  }

  String? _readGoalId(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return value.toString();
  }
}

class ActiveGoalControllerProvider
    extends InheritedNotifier<ActiveGoalController> {
  const ActiveGoalControllerProvider({
    super.key,
    required ActiveGoalController controller,
    required super.child,
  }) : super(notifier: controller);

  static ActiveGoalController of(BuildContext context, {bool listen = true}) {
    final provider = listen
        ? context
            .dependOnInheritedWidgetOfExactType<ActiveGoalControllerProvider>()
        : context
            .getElementForInheritedWidgetOfExactType<
                ActiveGoalControllerProvider>()
            ?.widget as ActiveGoalControllerProvider?;
    assert(
      provider != null,
      'ActiveGoalControllerProvider.of() used with no controller in context',
    );
    return provider!.notifier!;
  }

  @override
  bool updateShouldNotify(
    covariant InheritedNotifier<ActiveGoalController> oldWidget,
  ) =>
      true;
}
