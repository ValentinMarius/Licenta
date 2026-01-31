// lib/app/features/profile/presentation/screens/profile_tab.dart
// Displays lightweight profile info and session controls.
// Exists so logout and signup prompts stay separate from goal management.
// RELEVANT FILES:lib/app/features/home/root/main_tab_shell.dart,lib/app/features/home/presentation/screens/home_screen.dart,lib/app/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:treespora/app/features/onboarding/presentation/widgets/animated_button.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
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
    return isSignedIn ? _buildSignedIn(context) : _buildSignedOut(context);
  }

  Widget _buildSignedOut(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pressed = Color.alphaBlend(
      colorScheme.onPrimary.withOpacity(0.12),
      colorScheme.primary,
    );
    return Center(
      child: SizedBox(
        width: 240,
        child: AnimatedButton(
          onTap: onRequireSignup,
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          backgroundColor: colorScheme.primary,
          textColor: colorScheme.onPrimary,
          pressedBackgroundColor: pressed,
          pressedTextColor: colorScheme.onPrimary,
          child: Text(
            'Create your account',
            style: theme.textTheme.labelLarge,
          ),
        ),
      ),
    );
  }

  Widget _buildSignedIn(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pressed = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.12),
      colorScheme.surfaceVariant,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Signed in as ${userEmail ?? 'member'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          child: AnimatedButton(
            onTap: onLogout,
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            backgroundColor: colorScheme.surfaceVariant,
            textColor: colorScheme.onSurface,
            pressedBackgroundColor: pressed,
            pressedTextColor: colorScheme.onSurface,
            child: const Text('Log out'),
          ),
        ),
      ],
    );
  }
}
