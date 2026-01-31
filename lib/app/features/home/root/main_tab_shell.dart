// lib/app/features/home/root/main_tab_shell.dart
// Root tab shell that keeps goal, home, and forest content organized.
// Exists to centralize auth-aware routing, profile access, and active-goal sync.
// RELEVANT FILES:lib/app/features/home/presentation/screens/home_screen.dart,lib/app/features/home/presentation/screens/journey_goal_tab.dart,lib/app/features/forest/presentation/screens/forest_tab.dart,lib/app/features/home/presentation/widgets/home_bottom_nav_bar.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/core/routes.dart';
import 'package:treespora/app/core/theme/app_canvas_background.dart';
import 'package:treespora/app/features/auth/data/auth_repository.dart';
import 'package:treespora/app/features/auth/presentation/widgets/signup_form.dart';
import 'package:treespora/app/features/forest/presentation/screens/forest_tab.dart';
import 'package:treespora/app/features/goals/state/active_goal_controller.dart';
import 'package:treespora/app/features/home/presentation/screens/home_screen.dart';
import 'package:treespora/app/features/home/presentation/screens/journey_goal_tab.dart';
import 'package:treespora/app/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:treespora/app/features/profile/presentation/screens/profile_content.dart';

class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  int _currentIndex = 1;
  bool _wasSignedIn = false;
  ActiveGoalController? _activeGoalController;

  bool get _isSignedIn => AuthRepository.instance.hasActiveSession;
  String? get _userEmail => AuthRepository.instance.currentUser?.email;

  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await AuthRepository.instance.signOut();
    _activeGoalController?.clearActiveGoal();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  void _openSignUpSheet() {
    _showBottomSheet(
      title: 'Create Account',
      child: SignUpForm(
        onSuccess: () {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _showBottomSheet({
    required String title,
    required Widget child,
  }) async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncActiveGoalState() {
    if (_activeGoalController == null) {
      return;
    }
    if (_isSignedIn && !_wasSignedIn) {
      _activeGoalController!.loadActiveGoal();
    } else if (!_isSignedIn && _wasSignedIn) {
      _activeGoalController!.clearActiveGoal();
    }
    _wasSignedIn = _isSignedIn;
  }

  @override
  Widget build(BuildContext context) {
    _activeGoalController ??= ActiveGoalControllerProvider.of(
      context,
      listen: false,
    );
    _syncActiveGoalState();

    final colorScheme = Theme.of(context).colorScheme;

    final tabs = <Widget>[
      const JourneyGoalTab(),
      const HomeScreen(),
      ForestTab(
        isSignedIn: _isSignedIn,
        userEmail: _userEmail,
        onRequireSignup: _openSignUpSheet,
        activeGoalController: _activeGoalController,
      ),
      ProfileContent(
        isSignedIn: _isSignedIn,
        userEmail: _userEmail,
        onLogout: _handleLogout,
        onRequireSignup: _openSignUpSheet,
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: AppCanvasBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            child: IndexedStack(index: _currentIndex, children: tabs),
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
