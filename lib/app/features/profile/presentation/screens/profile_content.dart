// lib/app/features/profile/presentation/screens/profile_content.dart
// Displays profile header with avatar and name, plus settings gear icon.
// Exists so Profile can be shown both as a tab and as a standalone screen wrapper.
// RELEVANT FILES:lib/app/features/profile/presentation/screens/settings_screen.dart,lib/app/features/profile/data/profile_repository.dart,lib/app/features/auth/data/auth_repository.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/auth/data/auth_repository.dart';
import 'package:treespora/app/features/profile/presentation/screens/settings_screen.dart';
import 'package:treespora/app/features/onboarding/presentation/widgets/animated_button.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({
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

  String? get _userName {
    final user = AuthRepository.instance.currentUser;
    // Try first_name and last_name first
    final firstName = user?.userMetadata?['first_name'] as String?;
    final lastName = user?.userMetadata?['last_name'] as String?;
    final nameParts = [firstName, lastName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim())
        .toList();
    if (nameParts.isNotEmpty) {
      return nameParts.join(' ');
    }
    // Fallback to full_name for backwards compatibility
    final fullName = user?.userMetadata?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return null;
  }

  String get _displayName {
    if (_userName != null) return _userName!;
    if (userEmail != null) {
      // Extract name from email (before @)
      final atIndex = userEmail!.indexOf('@');
      if (atIndex > 0) {
        return userEmail!.substring(0, atIndex);
      }
    }
    return 'User';
  }

  String get _avatarInitial {
    final name = _displayName;
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(
          userEmail: userEmail,
          userName: _userName ?? _displayName,
          onLogout: onLogout,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up animation
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
      return _buildSignedOut(context);
    }
    return _buildSignedIn(context);
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
          child: Text('Create your account', style: theme.textTheme.labelLarge),
        ),
      ),
    );
  }

  Widget _buildSignedIn(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: avatar + name on left, settings icon on right
        Row(
          children: [
            // Avatar circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceVariant,
              ),
              child: Center(
                child: Text(
                  _avatarInitial,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // User name
            Expanded(
              child: Text(
                _displayName,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Settings gear icon
            IconButton(
              onPressed: () => _openSettings(context),
              icon: Icon(
                Icons.settings_outlined,
                color: colorScheme.onSurface,
                size: 26,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
