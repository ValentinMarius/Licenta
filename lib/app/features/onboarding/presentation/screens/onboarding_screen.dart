// lib/app/features/onboarding/presentation/screens/onboarding_screen.dart
// Displays the first onboarding step where users pick their seed category.
// Captures the category answer, persists it, and forwards the onboarding state.
// RELEVANT FILES:lib/app/features/onboarding/presentation/screens/journey_stage_screen.dart,lib/app/features/onboarding/state/onboarding_state.dart,lib/app/features/onboarding/data/onboarding_storage.dart

import 'package:flutter/material.dart';
import 'package:treespora/app/core/theme/app_canvas_background.dart';
import 'package:treespora/app/core/routes.dart';

import '../widgets/rounded_progress_bar.dart';
import '../widgets/animated_button.dart';
import '../../state/onboarding_state.dart';
import '../../data/onboarding_storage.dart';
import 'journey_stage_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  double progress = 0.0;
  double previousProgress = 0.0;
  String? _selectedCategory;
  OnboardingState _flowState = const OnboardingState.initial();

  @override
  void initState() {
    super.initState();
    _restorePersistedState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        previousProgress = 0.0;
        progress = 0.25;
      });
    });
  }

  Future<void> _restorePersistedState() async {
    final stored = await OnboardingStorage.readState();
    if (!mounted) return;
    setState(() {
      _flowState = stored;
      _selectedCategory = stored.category != OnboardingState.skipValue
          ? stored.category
          : null;
    });
  }

  void _navigateToJourneyStage(OnboardingState state) {
    Navigator.of(context)
        .push(
          AppRoutes.onboardingRoute(
            builder: (_) => JourneyStageScreen(
              previousProgress: progress,
              targetProgress: 0.5,
              initialState: state,
            ),
            settings: RouteSettings(
              name: AppRoutes.journeyStage,
              arguments: state.category,
            ),
          ),
        )
        .then((_) {
          setState(() {
            previousProgress = 0.5;
          });

          Future.delayed(const Duration(milliseconds: 100), () {
            setState(() {
              progress = 0.25;
            });
          });
        });
  }

  Future<void> _persistAndNavigate(String categoryValue) async {
    final updated = _flowState.copyWith(category: categoryValue);
    setState(() {
      _flowState = updated;
    });
    await OnboardingStorage.saveState(updated);
    if (!mounted) return;
    _navigateToJourneyStage(updated);
  }

  void _skipOnboarding() {
    _persistAndNavigate(OnboardingState.skipValue);
  }

  @override
  Widget build(BuildContext context) {
    const List<String> categories = [
      'Physical Health & Fitness',
      'Mind & Well-being',
      'Career & Productivity',
      'Learning & Growth',
      'Financial Goals',
      'Creative Projects',
      'Skills & Hobbies',
      'Custom Seed',
    ];

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: colorScheme.onSurfaceVariant,
                        iconSize: 26,
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 24,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 148,
                          child: RoundedProgressBar(
                            value: progress,
                            startValue: previousProgress,
                            height: 4,
                            borderRadius: 8,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: TextButton(
                        onPressed: _skipOnboarding,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                        child: Text(
                          'Skip',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'What kind of seed do you want to plant today?',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: AnimatedButton(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  isSelected: _selectedCategory == category,
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                    maxHeight: 52,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  textStyle:
                                      textTheme.titleMedium ??
                                      const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.15,
                                      ),
                                  child: Text(
                                    category,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: AnimatedButton(
                      onTap: () {
                        final selection = _selectedCategory;
                        if (selection != null) {
                          _persistAndNavigate(selection);
                        }
                      },
                      enabled: _selectedCategory != null,
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxHeight: 48,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                      ),
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      pressedBackgroundColor: primaryPressedColor,
                      pressedTextColor: colorScheme.onPrimary,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Continue'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
