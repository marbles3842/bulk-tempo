import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_form_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/hevy_key_bottom_sheet.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/weekly_workout_card.dart';

/// Presentation view for the Workouts tab, displaying the inline Hevy API key
/// onboarding flow when unconfigured or the 12-week ISO weekly workout history.
class WorkoutProgressView extends ConsumerStatefulWidget {
  const WorkoutProgressView({super.key});

  @override
  ConsumerState<WorkoutProgressView> createState() =>
      _WorkoutProgressViewState();
}

class _WorkoutProgressViewState extends ConsumerState<WorkoutProgressView> {
  late final TextEditingController _inlineKeyController;

  @override
  void initState() {
    super.initState();
    _inlineKeyController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(workoutProgressViewModelProvider.notifier).ensureInitialized();
    });
  }

  @override
  void dispose() {
    _inlineKeyController.dispose();
    super.dispose();
  }

  Widget _buildUnconfiguredState(BuildContext context) {
    final keyFormState = ref.watch(hevyKeyViewModelProvider);
    final theme = Theme.of(context);
    final isSubmitting = keyFormState.status == FormStatus.submitting;

    return Center(
      key: const Key('workout_unconfigured_state'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.fitness_center,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect Hevy Workouts',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import your last 12 weeks of workouts directly from Hevy. '
              'Generate your Hevy Pro API key at https://hevy.com/settings?developer and enter it below.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (keyFormState.submitErrorMessage != null) ...[
              Container(
                key: const Key('hevy_key_inline_error_banner'),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        keyFormState.submitErrorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            TextField(
              key: const Key('hevy_key_inline_input_field'),
              controller: _inlineKeyController,
              enabled: !isSubmitting,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Hevy API Key (UUID)',
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                errorText: keyFormState.validationError,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              onChanged: (value) {
                ref.read(hevyKeyViewModelProvider.notifier).updateKey(value);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('hevy_key_inline_connect_button'),
              onPressed: isSubmitting
                  ? null
                  : () {
                      ref.read(hevyKeyViewModelProvider.notifier).submitKey();
                    },
              icon: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link),
              label: const Text('Connect Hevy'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('workout_progress_error_state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('workout_progress_retry_button'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                ref
                    .read(workoutProgressViewModelProvider.notifier)
                    .loadWorkouts();
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('workout_error_update_key_button'),
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('Update API Key'),
              onPressed: () => HevyKeyBottomSheet.show(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, WorkoutProgressLoaded loaded) {
    final theme = Theme.of(context);
    final weeklySummaries = loaded.weeklySummaries;

    if (weeklySummaries.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref
            .read(workoutProgressViewModelProvider.notifier)
            .loadWorkouts(showLoading: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                key: const Key('workout_progress_empty_state'),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workouts in the last 12 weeks',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log a workout in Hevy and refresh to see your weekly training volume.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('workout_empty_refresh_button'),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Workouts'),
                        onPressed: () {
                          ref
                              .read(workoutProgressViewModelProvider.notifier)
                              .loadWorkouts();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(workoutProgressViewModelProvider.notifier)
          .loadWorkouts(showLoading: false),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: weeklySummaries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 12 Weeks (${loaded.workouts.length} ${loaded.workouts.length == 1 ? "workout" : "workouts"})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('workout_refresh_button'),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    onPressed: () {
                      ref
                          .read(workoutProgressViewModelProvider.notifier)
                          .loadWorkouts(showLoading: false);
                    },
                  ),
                ],
              ),
            );
          }

          final summaryIndex = index - 1;
          final summary = weeklySummaries[summaryIndex];
          return WeeklyWorkoutCard(
            key: PageStorageKey<String>(
              'workout_week_card_outer_${summary.weekStartIso}',
            ),
            summary: summary,
            initiallyExpanded: summaryIndex == 0,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HevyKeyFormState>(hevyKeyViewModelProvider, (previous, next) {
      if (next.rawKey != _inlineKeyController.text) {
        _inlineKeyController.text = next.rawKey;
      }
    });

    ref.listen<WorkoutProgressState>(workoutProgressViewModelProvider, (
      previous,
      next,
    ) {
      if (next is WorkoutProgressInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(workoutProgressViewModelProvider.notifier)
              .ensureInitialized();
        });
      }

      if (next is WorkoutProgressLoaded && next.refreshErrorMessage != null) {
        final prevError = previous is WorkoutProgressLoaded
            ? previous.refreshErrorMessage
            : null;
        if (next.refreshErrorMessage != prevError) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              key: const Key('workout_progress_refresh_error_snackbar'),
              content: Text(next.refreshErrorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                key: const Key('workout_progress_refresh_retry_action'),
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  ref
                      .read(workoutProgressViewModelProvider.notifier)
                      .loadWorkouts(showLoading: false);
                },
              ),
            ),
          );
          ref
              .read(workoutProgressViewModelProvider.notifier)
              .clearRefreshError();
        }
      }
    });

    final workoutState = ref.watch(workoutProgressViewModelProvider);

    Widget content;
    switch (workoutState) {
      case WorkoutProgressInitial() || WorkoutProgressLoading():
        content = const Center(
          child: CircularProgressIndicator(
            key: Key('workout_progress_loading_indicator'),
          ),
        );
      case WorkoutProgressUnconfigured():
        content = _buildUnconfiguredState(context);
      case WorkoutProgressError(:final message):
        content = _buildErrorState(context, message);
      case final WorkoutProgressLoaded loaded:
        content = _buildLoadedState(context, loaded);
    }

    return Scaffold(body: SafeArea(child: content));
  }
}
