// lib/app/features/profile/presentation/screens/account_screen.dart
// Displays user account details: Name, Age, Email address.
// Opens with slide-right animation from the Settings screen.
// RELEVANT FILES:lib/app/features/profile/presentation/screens/settings_screen.dart,lib/app/features/profile/data/profile_repository.dart,lib/app/features/auth/data/auth_repository.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/auth/data/auth_repository.dart';
import 'package:treespora/app/features/profile/data/profile_repository.dart';
import 'package:treespora/app/features/profile/presentation/screens/delete_account_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  final String? userEmail;
  final String? userName;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ProfileRepository _profileRepository = ProfileRepository.instance;
  bool _loading = true;
  ProfileData _profileData = const ProfileData();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _profileRepository.fetchProfile();
    ProfileData merged = data ?? const ProfileData();

    // Merge with user metadata if data is missing from profiles
    final user = AuthRepository.instance.currentUser;
    if (merged.gender == null || merged.gender!.isEmpty) {
      final metaGender = user?.userMetadata?['gender'] as String?;
      if (metaGender != null && metaGender.isNotEmpty) {
        merged = merged.copyWith(gender: metaGender);
      }
    }
    if (merged.firstName == null || merged.firstName!.isEmpty) {
      final metaFirstName = user?.userMetadata?['first_name'] as String?;
      if (metaFirstName != null && metaFirstName.isNotEmpty) {
        merged = merged.copyWith(firstName: metaFirstName);
      }
    }
    if (merged.lastName == null || merged.lastName!.isEmpty) {
      final metaLastName = user?.userMetadata?['last_name'] as String?;
      if (metaLastName != null && metaLastName.isNotEmpty) {
        merged = merged.copyWith(lastName: metaLastName);
      }
    }

    if (!mounted) return;
    setState(() {
      _profileData = merged;
      _loading = false;
    });
  }

  /// Constructs full name from firstName and lastName
  String get _fullName {
    final parts = [_profileData.firstName, _profileData.lastName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim())
        .toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    return widget.userName ?? 'Not set';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Account',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colorScheme.outlineVariant),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Name row
                  _AccountRow(
                    label: 'Name',
                    value: _fullName,
                    onTap: () {
                      // Future: open name edit screen
                    },
                  ),
                  // Age row
                  _AccountRow(
                    label: 'Age',
                    value: _profileData.age?.toString() ?? 'Not set',
                    onTap: () {
                      // Future: open age edit screen
                    },
                  ),
                  // Gender row
                  _AccountRow(
                    label: 'Gender',
                    value: _profileData.gender ?? 'Not set',
                    onTap: () {
                      // Future: open gender edit screen
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      height: 1,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email row
                  _AccountRow(
                    label: 'Email address',
                    value: widget.userEmail ?? 'Not set',
                    onTap: () {
                      // Future: open email edit screen
                    },
                  ),
                  const Spacer(),
                  // Delete account button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: GestureDetector(
                      onTap: () => _openDeleteAccountScreen(context),
                      child: Text(
                        'Delete account',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _openDeleteAccountScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DeleteAccountScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
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
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
