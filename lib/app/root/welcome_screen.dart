// lib/app/root/welcome_screen.dart
// Landing screen that welcomes users and routes them to onboarding or auth.
// Hosts the login bottom sheet for returning members.
// RELEVANT FILES:lib/app/features/onboarding/presentation/screens/onboarding_screen.dart,lib/app/features/auth/presentation/widgets/login_form.dart,lib/app/root/startup_screen.dart

import 'package:flutter/material.dart';
import 'package:treespora/app/core/theme/app_canvas_background.dart';
import 'package:treespora/app/core/routes.dart';
import 'package:treespora/app/features/auth/presentation/widgets/login_form.dart';
import 'package:treespora/app/features/onboarding/presentation/widgets/animated_button.dart';
import 'package:treespora/app/features/onboarding/data/onboarding_storage.dart';
import 'package:treespora/app/features/onboarding/state/onboarding_state.dart';
import 'package:treespora/app/features/profile/data/profile_repository.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _logoAnimation;
  String _languageCode = ProfileData.allowedLanguages.first;
  bool _loadingLanguage = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _logoAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -225),
    ).animate(_animationController);
    _loadSavedLanguage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openOnboarding(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.onboarding);
  }

  Future<void> _loadSavedLanguage() async {
    final state = await OnboardingStorage.readState();
    final fromOnboarding = state.language != OnboardingState.skipValue
        ? state.language
        : null;
    if (!mounted) return;
    setState(() {
      _languageCode = fromOnboarding ?? ProfileData.allowedLanguages.first;
      _loadingLanguage = false;
    });
  }

  Future<void> _selectLanguage(String code) async {
    setState(() {
      _languageCode = code;
    });
    final current = await OnboardingStorage.readState();
    final updated = current.copyWith(language: code);
    await OnboardingStorage.saveState(updated);
    await ProfileRepository.instance.upsertProfile(
      ProfileData(languageCode: code),
    );
  }

  void _handleLoginSuccess() {
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _openLoginSheet() {
    _showBottomSheetForm(
      context,
      title: 'Log In',
      child: LoginForm(onSuccess: _handleLoginSuccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final primaryPressedColor = Color.alphaBlend(
      colorScheme.onPrimary.withOpacity(0.12),
      colorScheme.primary,
    );

    return AppCanvasBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    if (!_loadingLanguage)
                      _LanguageSelector(
                        current: _languageCode,
                        onChanged: _selectLanguage,
                      ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _logoAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: _logoAnimation.value,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/Treespora_logo_transparent.png',
                            height: 300,
                          ),
                        ),
                        const SizedBox(height: 80),
                        SizedBox(
                          width: 220,
                          child: AnimatedButton(
                            onTap: () => _openOnboarding(context),
                            width: 220,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 22,
                            ),
                            backgroundColor: colorScheme.primary,
                            textColor: colorScheme.onPrimary,
                            pressedBackgroundColor: primaryPressedColor,
                            pressedTextColor: colorScheme.onPrimary,
                            child: Text(
                              'GET STARTED',
                              style: textTheme.labelLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _openLoginSheet,
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                            splashFactory: NoSplash.splashFactory,
                          ),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Already have an account? ',
                                ),
                                TextSpan(
                                  text: 'Log In',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Removed 'Create account' button as requested.
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBottomSheetForm(
    BuildContext context, {
    required String title,
    required Widget child,
  }) async {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    _animationController.forward();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: textTheme.titleLarge),
                const SizedBox(height: 20),

                child,

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
    _animationController.reverse();
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          elevation: 0,
          dropdownColor: colorScheme.surface,
          items: ProfileData.allowedLanguages
              .map(
                (code) => DropdownMenuItem<String>(
                  value: code,
                  child: Text(
                    code.toUpperCase(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
