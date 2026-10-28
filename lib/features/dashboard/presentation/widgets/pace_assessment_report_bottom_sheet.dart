import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/pace_assessment_card.dart';

/// Modal bottom sheet displaying the full multi-section AI pace assessment report.
class PaceAssessmentReportBottomSheet extends StatelessWidget {
  final PaceAssessmentEntity assessment;
  final int? assessedWeekLoggedDays;

  const PaceAssessmentReportBottomSheet({
    super.key,
    required this.assessment,
    this.assessedWeekLoggedDays,
  });

  /// Presents [PaceAssessmentReportBottomSheet] modally for [assessment].
  static Future<void> show(
    BuildContext context,
    PaceAssessmentEntity assessment, {
    int? assessedWeekLoggedDays,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaceAssessmentReportBottomSheet(
        assessment: assessment,
        assessedWeekLoggedDays: assessedWeekLoggedDays,
      ),
    );
  }

  String _formatAssessedWeekRange(BuildContext context) {
    final parsedMonday = WeekDateUtils.tryParseIsoDate(
      assessment.assessedWeekStartIso,
    );
    if (parsedMonday == null) {
      return assessment.assessedWeekStartIso;
    }
    final sunday = WeekDateUtils.endOfIsoWeekUtc(parsedMonday);
    final locale = Localizations.localeOf(context).languageCode;
    return WeekDateUtils.formatWeekRange(parsedMonday, sunday, locale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colors = PaceAssessmentCard.statusColors(assessment.status, theme);
    final statusLabel = PaceAssessmentCard.formatStatusLabel(
      assessment.status,
      l10n,
    );
    final baselineLabel = PaceAssessmentCard.formatStatusLabel(
      assessment.baselineStatus,
      l10n,
    );
    final loggedDays = assessedWeekLoggedDays ?? 1;

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
                            l10n.paceReportTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatAssessedWeekRange(context),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      colors.icon,
                                      size: 15,
                                      color: colors.foreground,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      statusLabel,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: colors.foreground,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (assessment.isAssessedWeekPartial)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    l10n.paceAssessmentPartialWeekBadge(
                                      loggedDays,
                                    ),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (assessment.status !=
                              assessment.baselineStatus) ...[
                            const SizedBox(height: 6),
                            Text(
                              l10n.paceReportBaselineLabel(baselineLabel),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('pace_report_close_button'),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _ReportSectionCard(
                      key: const Key('pace_report_weight_section'),
                      icon: Icons.monitor_weight_outlined,
                      title: l10n.paceReportWeightTrendSection,
                      child: Text(
                        assessment.weightTrendAnalysis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    _ReportSectionCard(
                      key: const Key('pace_report_workout_section'),
                      icon: Icons.fitness_center_outlined,
                      title: l10n.paceReportWorkoutContextSection,
                      child: Text(
                        assessment.workoutContextAnalysis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    _ReportSectionCard(
                      key: const Key('pace_report_takeaways_section'),
                      icon: Icons.lightbulb_outline,
                      title: l10n.paceReportTakeawaysSection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (
                            var i = 0;
                            i < assessment.actionableTakeaways.length;
                            i++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    i ==
                                        assessment.actionableTakeaways.length -
                                            1
                                    ? 0
                                    : 8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      assessment.actionableTakeaways[i],
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ReportSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
