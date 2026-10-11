import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

/// Modal bottom sheet displaying the full exercise and set breakdown for a
/// single logged [WorkoutEntity].
class WorkoutDetailBottomSheet extends StatelessWidget {
  final WorkoutEntity workout;

  const WorkoutDetailBottomSheet({super.key, required this.workout});

  /// Presents [WorkoutDetailBottomSheet] modally for [workout].
  static Future<void> show(BuildContext context, WorkoutEntity workout) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutDetailBottomSheet(workout: workout),
    );
  }

  static String formatSetPerformance(WorkoutSetEntity set) {
    if (set.weightKg != null && set.reps != null) {
      return '${set.weightKg!.toStringAsFixed(2)} kg × ${set.reps}';
    }
    if (set.weightKg != null) {
      return '${set.weightKg!.toStringAsFixed(2)} kg';
    }
    if (set.reps != null) {
      return '${set.reps} ${set.reps == 1 ? "rep" : "reps"}';
    }
    if (set.durationSeconds != null) {
      return '${set.durationSeconds}s';
    }
    if (set.distanceMeters != null) {
      return '${set.distanceMeters!.toStringAsFixed(0)}m';
    }
    return '—';
  }

  static String formatSetTypeLabel(WorkoutSetEntity set) {
    switch (set.type) {
      case 'warmup':
        return 'Warmup';
      case 'failure':
        return 'Failure';
      case 'dropset':
        return 'Dropset';
      case 'normal':
      default:
        return 'Working';
    }
  }

  String _formatDateAndDuration() {
    final dateText = WeekDateUtils.formatDayWithWeekday(workout.localDate);
    final durationMinutes = workout.endTime
        .difference(workout.startTime)
        .inMinutes;
    if (durationMinutes > 0) {
      return '$dateText • $durationMinutes min';
    }
    return dateText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateAndDuration(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${workout.workingSetsCount} working sets • ${workout.totalVolumeKg.toStringAsFixed(2)} kg volume',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('workout_detail_close_button'),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: workout.exercises.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises recorded for this workout.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: workout.exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = workout.exercises[index];
                          return _ExerciseCard(exercise: exercise);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExerciseEntity exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestSet = exercise.bestWorkingSet;

    return Card(
      key: Key('workout_exercise_${exercise.index}'),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exercise.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (bestSet != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Best: ${WorkoutDetailBottomSheet.formatSetPerformance(bestSet)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (exercise.notes != null &&
                exercise.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                exercise.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...exercise.sets.map((set) {
              final isWarmup = !set.isWorkingSet;
              final badgeColor = isWarmup
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.secondaryContainer;
              final badgeTextColor = isWarmup
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSecondaryContainer;

              return Padding(
                key: Key('workout_set_${exercise.index}_${set.index}'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#${set.index + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        WorkoutDetailBottomSheet.formatSetTypeLabel(set),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: badgeTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      WorkoutDetailBottomSheet.formatSetPerformance(set),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isWarmup
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: isWarmup
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
