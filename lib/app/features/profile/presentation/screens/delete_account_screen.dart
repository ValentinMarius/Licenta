// lib/app/features/profile/presentation/screens/delete_account_screen.dart
// Collects feedback on why the user wants to delete their account.
// Opens with slide-right animation from the Account screen.
// RELEVANT FILES:lib/app/features/profile/presentation/screens/account_screen.dart,lib/app/features/profile/data/deletion_feedback_repository.dart,lib/app/features/auth/data/auth_repository.dart

import 'package:flutter/material.dart';

import 'package:treespora/app/features/auth/data/auth_repository.dart';
import 'package:treespora/app/features/profile/data/deletion_feedback_repository.dart';
import 'package:treespora/app/core/routes.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final Set<String> _selectedReasons = {};
  bool _loading = false;

  static const List<String> _reasons = [
    'Treespora is too hard for me.',
    'Treespora is not useful to me.',
    'I accidentally made multiple Treespora accounts.',
    'I do not understand how to use Treespora.',
    'I have a privacy concern.',
    'Treespora sends me too many notifications.',
    'I am spending too much time on Treespora.',
    'Other',
  ];

  void _toggleReason(String reason) {
    setState(() {
      if (_selectedReasons.contains(reason)) {
        _selectedReasons.remove(reason);
      } else {
        _selectedReasons.add(reason);
      }
    });
  }

  Future<void> _confirmAndDelete() async {
    if (_selectedReasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one reason.')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action is irreversible and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    try {
      final authRepo = AuthRepository.instance;
      final user = authRepo.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // 1. Save feedback first (before deleting anything)
      await DeletionFeedbackRepository.instance.saveFeedback(
        userId: user.id,
        userEmail: user.email,
        reasons: _selectedReasons.toList(),
      );

      // 2. Delete account (this will trigger cascade deletes in Supabase)
      await authRepo.deleteAccount();

      // 3. Sign out
      await authRepo.signOut();

      if (!mounted) return;

      // 4. Navigate to welcome screen and clear navigation stack
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
    }
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
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Delete account',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colorScheme.outlineVariant),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Let us know why you are leaving, to help us improve Treespora for future generations',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            // Reasons list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _reasons.length,
                itemBuilder: (context, index) {
                  final reason = _reasons[index];
                  final isSelected = _selectedReasons.contains(reason);

                  return _ReasonCheckbox(
                    reason: reason,
                    isSelected: isSelected,
                    onTap: _loading ? null : () => _toggleReason(reason),
                  );
                },
              ),
            ),
            // Delete button at bottom
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmAndDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete my account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkbox row for deletion reason selection
class _ReasonCheckbox extends StatelessWidget {
  const _ReasonCheckbox({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final String reason;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Custom checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: 2,
                ),
                color: isSelected ? colorScheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 14),
            // Reason text
            Expanded(
              child: Text(
                reason,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
