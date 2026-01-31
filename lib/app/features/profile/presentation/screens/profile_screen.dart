// lib/app/features/profile/presentation/screens/profile_screen.dart
// Wraps the full Profile content inside a standalone screen outside the bottom nav.
// Exists so Profile can be opened modally while still reusing the same content widget.
// RELEVANT FILES:lib/app/features/profile/presentation/screens/profile_content.dart,lib/app/features/home/root/main_tab_shell.dart,lib/app/core/theme/app_canvas_background.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/core/theme/app_canvas_background.dart';
import 'package:treespora/app/features/profile/presentation/screens/profile_content.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.isSignedIn,
    required this.userEmail,
    required this.onLogout,
    required this.onRequireSignup,
  });

  final bool isSignedIn;
  final String? userEmail;
  final VoidCallback onLogout;
  final VoidCallback onRequireSignup;

  @override
  Widget build(BuildContext context) {
    return AppCanvasBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                ProfileContent(
                  isSignedIn: isSignedIn,
                  userEmail: userEmail,
                  onLogout: onLogout,
                  onRequireSignup: onRequireSignup,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
