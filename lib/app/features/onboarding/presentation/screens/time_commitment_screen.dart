// lib/app/features/onboarding/presentation/screens/time_commitment_screen.dart
// Asks the user how much time they can invest daily.
// Persists the choice and forwards the onboarding state to the discovery source step.
// RELEVANT FILES:lib/app/features/onboarding/presentation/screens/source_screen.dart,lib/app/features/onboarding/state/onboarding_state.dart,lib/app/features/onboarding/data/onboarding_storage.dart

import 'package:flutter/material.dart';
import 'package:treespora/app/core/theme/app_canvas_background.dart';
import 'package:treespora/app/core/routes.dart';

import '../widgets/animated_button.dart';
import '../widgets/rounded_progress_bar.dart';
import '../../state/onboarding_state.dart';
import '../../data/onboarding_storage.dart';
import 'source_screen.dart';

class TimeCommitmentScreen extends StatefulWidget {
  final double previousProgress;
  final double targetProgress;
  final OnboardingState initialState;

  const TimeCommitmentScreen({
    super.key,
    this.previousProgress = 0.5,
    this.targetProgress = 0.75,
    this.initialState = const OnboardingState.initial(),
  });

  @override
  State<TimeCommitmentScreen> createState() => _TimeCommitmentScreenState();
}

class _TimeCommitmentScreenState extends State<TimeCommitmentScreen> {
  late double _progress;
  late double _previousProgress;
  String? _selectedCommitment;
  late OnboardingState _flowState;

  @override
  void initState() {
    super.initState();
    _flowState = widget.initialState;
    if (_flowState.timeCommitment != OnboardingState.skipValue) {
      _selectedCommitment = _flowState.timeCommitment;
    }
    _previousProgress = widget.previousProgress;
    _progress = widget.previousProgress;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _previousProgress = widget.previousProgress;
        _progress = widget.targetProgress;
      });
    });
  }

  void _handleBack(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  Future<void> _persistAndNavigate(String value) async {
    final updated = _flowState.copyWith(timeCommitment: value);
    setState(() {
      _flowState = updated;
    });
    await OnboardingStorage.saveState(updated);
    if (!mounted) return;
    _navigateToSource(updated);
  }

  void _navigateToSource(OnboardingState state) {
    Navigator.of(context).push(
      AppRoutes.onboardingRoute(
        builder: (_) => SourceScreen(
          previousProgress: widget.targetProgress,
          targetProgress: 1.0,
          initialState: state,
        ),
        settings: RouteSettings(
          name: AppRoutes.source,
          arguments: state.timeCommitment,
        ),
      ),
    );
  }

  void _skipOnboarding() {
    _persistAndNavigate(OnboardingState.skipValue);
  }

  @override
  Widget build(BuildContext context) {
    const options = [
      '10 minutes',
      '15–30 minutes',
      '30–60 minutes',
      '1 hour or more',
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
                        onPressed: () => _handleBack(context),
                        splashRadius: 24,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 148,
                          child: RoundedProgressBar(
                            value: _progress,
                            startValue: _previousProgress,
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
                        'How much time can you give your seed each day?',
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
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: AnimatedButton(
                                  onTap: () {
                                    setState(() {
                                      _selectedCommitment = option;
                                    });
                                  },
                                  isSelected: _selectedCommitment == option,
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
                                    option,
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
                        final selected = _selectedCommitment;
                        if (selected != null) {
                          _persistAndNavigate(selected);
                        }
                      },
                      enabled: _selectedCommitment != null,
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
