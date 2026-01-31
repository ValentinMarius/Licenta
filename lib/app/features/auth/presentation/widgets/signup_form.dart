// lib/app/features/auth/presentation/widgets/signup_form.dart
// Collects details for account creation after onboarding.
// Lives inside the MainTabShell so users can commit once they see the value.
// RELEVANT FILES:lib/app/features/auth/data/auth_repository.dart,lib/app/features/onboarding/data/onboarding_storage.dart,lib/app/features/home/root/main_tab_shell.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:treespora/app/features/auth/data/auth_repository.dart';
import 'package:treespora/app/features/onboarding/data/onboarding_storage.dart';
import 'package:treespora/app/features/profile/data/profile_repository.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  String? _errorMessage;
  String? _selectedGender;
  int? _selectedAge;

  static const List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final requiresEmailConfirmation = await AuthRepository.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender,
      );

      // Save profile data to profiles table
      if (!requiresEmailConfirmation) {
        await ProfileRepository.instance.upsertProfile(
          ProfileData(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            age: _selectedAge,
            gender: _selectedGender,
          ),
        );
      }

      await OnboardingStorage.ensureOnboardingDoneFlag();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requiresEmailConfirmation
                ? 'Account created! Please confirm your email to finish.'
                : 'Account created! Welcome to Treespora.',
          ),
        ),
      );
      widget.onSuccess?.call();
    } on AuthFlowException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Shows iOS-style age picker in a bottom sheet
  void _showAgePicker(BuildContext context, ColorScheme colorScheme) {
    // Age range: 13-100
    const minAge = 13;
    const maxAge = 100;
    final ages = List.generate(maxAge - minAge + 1, (i) => minAge + i);

    // Start at selected age or default to 25
    final initialIndex = _selectedAge != null
        ? (_selectedAge! - minAge).clamp(0, ages.length - 1)
        : 25 - minAge;

    int tempAge = _selectedAge ?? 25;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header with Done button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    'Select Age',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedAge = tempAge;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Picker wheel
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  tempAge = ages[index];
                },
                children: ages
                    .map(
                      (age) => Center(
                        child: Text(
                          '$age',
                          style: TextStyle(
                            fontSize: 22,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the age picker field that looks like a form field
  Widget _buildAgePicker(ColorScheme colorScheme, TextTheme textTheme) {
    return GestureDetector(
      onTap: _loading ? null : () => _showAgePicker(context, colorScheme),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Age',
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        child: Text(
          _selectedAge != null ? '$_selectedAge' : '',
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Join Treespora today!',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: 'First Name',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: 'Last Name',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          _buildAgePicker(colorScheme, textTheme),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            items: _genderOptions
                .map(
                  (gender) => DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_loading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_loading,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Minimum 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirmPassword,
            enabled: !_loading,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords must match';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign Up', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
