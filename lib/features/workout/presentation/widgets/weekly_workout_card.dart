import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart';

/// Expandable card displaying an ISO Monday–Sunday weekly workout summary and
/// its individual logged workouts.
class WeeklyWorkoutCard extends StatefulWidget {
  final WeeklyWorkoutSummaryEntity summary;
  final bool initiallyExpanded;
  final ValueChanged<WorkoutEntity>? onWorkoutTap;

  const WeeklyWorkoutCard({
    super.key,
    required this.summary,
    required this.initiallyExpanded,
    this.onWorkoutTap,
  });

  @override
  State<WeeklyWorkoutCard> createState() => _WeeklyWorkoutCardState();
}

class _WeeklyWorkoutCardState extends State<WeeklyWorkoutCard> {
  late bool _isExpanded;
  late final ExpansibleController _controller;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = ExpansibleController();
  }

  @override
  void didUpdateWidget(WeeklyWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
      if (widget.initiallyExpanded) {
        if (!_controller.isExpanded) {
          _controller.expand();
        }
      } else {
        if (_controller.isExpanded) {
          _controller.collapse();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel =
        '${widget.summary.workoutCount} ${widget.summary.workoutCount == 1 ? "workout" : "workouts"}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: Key('workout_week_card_${widget.summary.weekStartIso}'),
        controller: _controller,
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                WeekDateUtils.formatWeekRange(
                  widget.summary.weekStartMonday,
                  widget.summary.weekEndSunday,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                    child: child,
                  ),
                );
              },
              child: _isExpanded
                  ? const SizedBox.shrink(key: ValueKey('workout_count_empty'))
                  : Container(
                      key: Key(
                        'workout_count_chip_${widget.summary.weekStartIso}',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        countLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${widget.summary.totalWorkingSets} working sets • ${widget.summary.totalVolumeKg.toStringAsFixed(2)} kg volume',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: widget.summary.workouts.map((workout) {
          final exerciseCount = workout.exercises.length;
          final exerciseLabel =
              '$exerciseCount ${exerciseCount == 1 ? "exercise" : "exercises"}';
          final setsCount = workout.workingSetsCount;
          final setsLabel =
              '$setsCount working ${setsCount == 1 ? "set" : "sets"}';

          return ListTile(
            key: Key('workout_item_${workout.id}'),
            onTap: () {
              if (widget.onWorkoutTap != null) {
                widget.onWorkoutTap!(workout);
              } else {
                WorkoutDetailBottomSheet.show(context, workout);
              }
            },
            leading: Icon(
              Icons.fitness_center,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              workout.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${WeekDateUtils.formatDayWithWeekday(workout.localDate)} • $exerciseLabel • $setsLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${workout.totalVolumeKg.toStringAsFixed(2)} kg',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
