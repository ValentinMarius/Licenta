// lib/app/features/forest/presentation/screens/forest_tab.dart
// Displays the user's goals and active selection inside the Forest tab.
// Keeps goal management scoped to a single page until richer visuals arrive.
// RELEVANT FILES:lib/app/features/home/root/main_tab_shell.dart,lib/app/features/goals/data/goal_repository.dart,lib/app/features/goals/state/active_goal_controller.dart

import 'package:flutter/material.dart';
import 'package:treespora/app/features/onboarding/presentation/widgets/animated_button.dart';
import 'package:treespora/app/features/goals/data/goal_repository.dart';
import 'package:treespora/app/features/goals/domain/goal_summary.dart';
import 'package:treespora/app/features/goals/state/active_goal_controller.dart';

enum _PlanStartOption { today, tomorrow }

class ForestTab extends StatefulWidget {
  const ForestTab({
    super.key,
    required this.isSignedIn,
    required this.userEmail,
    required this.onRequireSignup,
    this.activeGoalController,
  });

  final bool isSignedIn;
  final String? userEmail;
  final VoidCallback onRequireSignup;
  final ActiveGoalController? activeGoalController;

  @override
  State<ForestTab> createState() => _ForestTabState();
}

class _ForestTabState extends State<ForestTab> {
  late Future<List<GoalSummary>> _goalsFuture;
  ActiveGoalController? _controller;
  bool _creatingGoal = false;

  @override
  void initState() {
    super.initState();
    _goalsFuture = _loadGoals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider =
        widget.activeGoalController ??
        ActiveGoalControllerProvider.of(context, listen: false);
    if (_controller == provider) {
      return;
    }
    _controller?.removeListener(_handleActiveGoalChange);
    _controller = provider;
    _controller?.addListener(_handleActiveGoalChange);
  }

  @override
  void didUpdateWidget(covariant ForestTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSignedIn != widget.isSignedIn) {
      _reloadGoals();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleActiveGoalChange);
    super.dispose();
  }

  Future<List<GoalSummary>> _loadGoals() {
    if (!widget.isSignedIn) {
      return Future.value(const []);
    }
    return GoalRepository.instance.fetchGoalsForCurrentUser();
  }

  void _reloadGoals() {
    setState(() {
      _goalsFuture = _loadGoals();
    });
  }

  void _handleActiveGoalChange() {
    if (!widget.isSignedIn) {
      return;
    }
    _reloadGoals();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSignedIn) {
      return _buildSignedOut(context);
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _controller?.loadActiveGoal();
        _reloadGoals();
        await _goalsFuture;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildCreateButton(context),
          const SizedBox(height: 24),
          _buildGoalsList(context),
        ],
      ),
    );
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
          onTap: widget.onRequireSignup,
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forest', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Manage your goals in one place.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Signed in as ${widget.userEmail ?? 'member'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pressed = Color.alphaBlend(
      colorScheme.onPrimary.withOpacity(0.12),
      colorScheme.primary,
    );
    return AnimatedButton(
      onTap: () {
        if (_creatingGoal) {
          return;
        }
        _showCreateGoalSheet(context);
      },
      enabled: !_creatingGoal,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
      backgroundColor: colorScheme.primary,
      textColor: colorScheme.onPrimary,
      pressedBackgroundColor: pressed,
      pressedTextColor: colorScheme.onPrimary,
      child: _creatingGoal
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text('Plant a new seed', style: theme.textTheme.labelLarge),
    );
  }

  Widget _buildGoalsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FutureBuilder<List<GoalSummary>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              snapshot.error.toString(),
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        final goals = snapshot.data ?? const <GoalSummary>[];
        if (goals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No goals yet. Plant a new seed to begin.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        final activeId = _controller?.activeGoalId;
        return Column(
          children: goals
              .map(
                (goal) => Card(
                  color: colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(goal.title),
                    subtitle: goal.createdAt != null
                        ? Text(
                            'Created ${_formatDate(goal.createdAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: goal.id == activeId
                        ? Chip(
                            label: const Text('Active'),
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.1,
                            ),
                            labelStyle: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : TextButton(
                            onPressed: () => _setActiveGoal(goal.id),
                            child: const Text('Set active'),
                          ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _setActiveGoal(String goalId) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    try {
      await controller.setActiveGoal(goalId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Active goal updated.')));
    } on ActiveGoalException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not change the active goal.')),
      );
    }
  }

  Future<void> _showCreateGoalSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final textController = TextEditingController();
    final durationController = TextEditingController(text: '4');
    const timeOptions = [
      '10 minutes',
      '15–30 minutes',
      '30–60 minutes',
      '1 hour or more',
    ];
    bool aiDuration = true;
    bool aiTime = true;
    _PlanStartOption planStartOption = _PlanStartOption.today;
    String selectedUnit = 'weeks';
    final units = ['days', 'weeks', 'months'];
    String? selectedTime = timeOptions.first;
    final description = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Describe your new goal',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Example: launch a mindful morning routine...',
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setSheetState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'When would you like your plan to start?',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<_PlanStartOption>(
                        value: _PlanStartOption.today,
                        groupValue: planStartOption,
                        onChanged: (value) {
                          setSheetState(() {
                            planStartOption = value ?? _PlanStartOption.today;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Start today'),
                      ),
                      RadioListTile<_PlanStartOption>(
                        value: _PlanStartOption.tomorrow,
                        groupValue: planStartOption,
                        onChanged: (value) {
                          setSheetState(() {
                            planStartOption = value ?? _PlanStartOption.today;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Start tomorrow'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'When do you want to finish?',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: durationController,
                              enabled: !aiDuration,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Value',
                                hintText: 'e.g. 4',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: selectedUnit,
                            items: units
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: aiDuration
                                ? null
                                : (val) {
                                    if (val == null) return;
                                    setSheetState(() {
                                      selectedUnit = val;
                                    });
                                  },
                          ),
                        ],
                      ),
                      CheckboxListTile(
                        value: aiDuration,
                        onChanged: (val) {
                          setSheetState(() {
                            aiDuration = val ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lasă AI să decidă pentru tine'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Time you can give per day',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in timeOptions)
                            ChoiceChip(
                              label: Text(option),
                              selected: !aiTime && selectedTime == option,
                              onSelected: aiTime
                                  ? null
                                  : (_) {
                                      setSheetState(() {
                                        selectedTime = option;
                                      });
                                    },
                            ),
                        ],
                      ),
                      CheckboxListTile(
                        value: aiTime,
                        onChanged: (val) {
                          setSheetState(() {
                            aiTime = val ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lasă AI să decidă pentru tine'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedButton(
                  onTap: () {
                    final buffer = StringBuffer(textController.text.trim());
                    if (!aiDuration &&
                        durationController.text.trim().isNotEmpty) {
                      buffer.write(
                        '\nPreferred completion: ${durationController.text.trim()} $selectedUnit',
                      );
                    } else {
                      buffer.write('\nPreferred completion: Let AI decide');
                    }
                    if (!aiTime && (selectedTime?.isNotEmpty ?? false)) {
                      buffer.write('\nDaily time: ${selectedTime!}');
                    } else {
                      buffer.write('\nDaily time: Let AI decide');
                    }
                    Navigator.of(context).pop(buffer.toString().trim());
                  },
                  width: 200,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  child: const Text('Save goal'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (description == null || description.isEmpty) {
      return;
    }

    final startDate = planStartOption == _PlanStartOption.today
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 1));
    final startDateIso = _formatDate(startDate);
    await _createGoal(description: description, startDateIso: startDateIso);
  }

  Future<void> _createGoal({
    required String description,
    required String startDateIso,
  }) async {
    setState(() {
      _creatingGoal = true;
    });
    try {
      final goalId = await GoalRepository.instance.createGoal(
        userInput: description,
        startDateIso: startDateIso,
      );
      await _controller?.setActiveGoal(goalId);
      _reloadGoals();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal planted successfully.')),
      );
    } on GoalCreationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on ActiveGoalException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not save the goal.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingGoal = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
