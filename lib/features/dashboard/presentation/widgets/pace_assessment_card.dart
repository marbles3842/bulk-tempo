import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/pace_assessment_state.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';

/// Top-of-Dashboard card displaying the AI pace assessment status badge,
/// headline summary, partial-week indicator, ineligibility guidance,
/// error/retry handling, and "View Full AI Report" action.
class PaceAssessmentCard extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onRefresh;
  final VoidCallback onOpenReport;

  const PaceAssessmentCard({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onOpenReport,
  });

  /// Returns the localized label for a [PaceAssessmentStatus].
  static String formatStatusLabel(
    PaceAssessmentStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case PaceAssessmentStatus.onTarget:
        return l10n.paceStatusOnTarget;
      case PaceAssessmentStatus.tooFast:
        return l10n.paceStatusTooFast;
      case PaceAssessmentStatus.tooSlow:
        return l10n.paceStatusTooSlow;
      case PaceAssessmentStatus.stagnant:
        return l10n.paceStatusStagnant;
    }
  }

  /// Returns background and foreground colors for a [PaceAssessmentStatus] badge.
  static ({Color background, Color foreground, IconData icon}) statusColors(
    PaceAssessmentStatus status,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    switch (status) {
      case PaceAssessmentStatus.onTarget:
        return (
          background: isDark
              ? const Color(0xFF065F46).withValues(alpha: 0.45)
              : const Color(0xFFD1FAE5),
          foreground: isDark
              ? const Color(0xFF6EE7B7)
              : const Color(0xFF065F46),
          icon: Icons.check_circle_outline,
        );
      case PaceAssessmentStatus.tooFast:
        return (
          background: isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.45)
              : const Color(0xFFFEF3C7),
          foreground: isDark
              ? const Color(0xFFFCD34D)
              : const Color(0xFF92400E),
          icon: Icons.trending_up,
        );
      case PaceAssessmentStatus.tooSlow:
        return (
          background: isDark
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.45)
              : const Color(0xFFDBEAFE),
          foreground: isDark
              ? const Color(0xFF93C5FD)
              : const Color(0xFF1E40AF),
          icon: Icons.trending_down,
        );
      case PaceAssessmentStatus.stagnant:
        return (
          background: theme.colorScheme.errorContainer,
          foreground: theme.colorScheme.onErrorContainer,
          icon: Icons.pause_circle_outline,
        );
    }
  }

  int _resolveAssessedWeekLoggedDays(PaceAssessmentEntity assessment) {
    for (final slot in state.overview.calendarWeeks) {
      if (slot.weekStartIso == assessment.assessedWeekStartIso &&
          slot.loggedWeightDaysCount > 0) {
        return slot.loggedWeightDaysCount;
      }
    }
    if (state.overview.latestWeekStartIso == assessment.assessedWeekStartIso &&
        state.overview.latestWeekLoggedDays > 0) {
      return state.overview.latestWeekLoggedDays;
    }
    return state.overview.latestWeekLoggedDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paceState = state.paceAssessment;
    final canRefresh =
        paceState.status == PaceAssessmentViewStatus.loaded &&
        paceState.assessment != null;

    final gradientColors = isDark
        ? [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.28),
          ]
        : [
            Color.alphaBlend(
              theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
              theme.colorScheme.surface,
            ),
            Color.alphaBlend(
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.40),
              theme.colorScheme.surface,
            ),
          ];

    return Card(
      key: const Key('dashboard_pace_assessment_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(
            alpha: isDark ? 0.45 : 0.28,
          ),
          width: 1.2,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.dashboardAssessmentCardTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (paceState.isOutdated) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        key: const Key('pace_assessment_outdated_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.l10n.dashboardOutdatedBadge,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (canRefresh) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('pace_assessment_refresh_button'),
                      visualDensity: VisualDensity.compact,
                      tooltip: context.l10n.paceAssessmentRefreshTooltip,
                      onPressed: paceState.isRefreshing ? null : onRefresh,
                      icon: paceState.isRefreshing
                          ? const AiTypingDotsIndicator(compact: true)
                          : const Icon(Icons.refresh, size: 20),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _buildBody(context, paceState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PaceAssessmentState paceState) {
    final theme = Theme.of(context);

    switch (paceState.status) {
      case PaceAssessmentViewStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: AiTypingDotsIndicator(
              key: Key('pace_assessment_typing_indicator'),
            ),
          ),
        );

      case PaceAssessmentViewStatus.ineligible:
        final message = _ineligibilityMessage(context, paceState);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  key: const Key('pace_assessment_ineligible_text'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );

      case PaceAssessmentViewStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                paceState.errorMessage ?? 'Failed to load data',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: const Key('pace_assessment_retry_button'),
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        );

      case PaceAssessmentViewStatus.loaded:
        final assessment = paceState.assessment;
        if (assessment == null) {
          return const SizedBox.shrink();
        }
        if (paceState.isRefreshing) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: AiTypingDotsIndicator(
                key: Key('pace_assessment_typing_indicator'),
              ),
            ),
          );
        }

        final colors = statusColors(assessment.status, theme);
        final statusLabel = formatStatusLabel(assessment.status, context.l10n);
        final loggedDays = _resolveAssessedWeekLoggedDays(assessment);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  key: const Key('pace_assessment_status_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(colors.icon, size: 16, color: colors.foreground),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (assessment.isAssessedWeekPartial)
                  Container(
                    key: const Key('pace_assessment_partial_week_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.l10n.paceAssessmentPartialWeekBadge(loggedDays),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AiChunkedText(
              text: assessment.headlineSummary,
              animationId:
                  '${assessment.fingerprint}_${assessment.generatedAt.millisecondsSinceEpoch}',
              textKey: const Key('pace_assessment_headline_text'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: const Key('pace_assessment_view_report_button'),
                onPressed: onOpenReport,
                icon: const Icon(Icons.description_outlined, size: 18),
                label: Text(context.l10n.paceAssessmentViewReportButton),
              ),
            ),
          ],
        );
    }
  }

  String _ineligibilityMessage(
    BuildContext context,
    PaceAssessmentState paceState,
  ) {
    final l10n = context.l10n;
    switch (paceState.ineligibilityReason) {
      case PaceAssessmentIneligibilityReason.missingGainTarget:
        return l10n.paceAssessmentMissingTarget;
      case PaceAssessmentIneligibilityReason.workoutUnconfigured:
        return l10n.paceAssessmentMissingHevy;
      case PaceAssessmentIneligibilityReason.noWorkoutsInWindow:
        return l10n.paceAssessmentNoWorkouts;
      case PaceAssessmentIneligibilityReason.insufficientWeightWeeks:
      case PaceAssessmentIneligibilityReason.unauthenticated:
      case null:
        return l10n.paceAssessmentInsufficientWeights(
          paceState.priorWeightWeeksCount,
        );
    }
  }
}

/// Three pulsing/bouncing dots indicator styled after AI chat assistants
/// (Gemini / ChatGPT) while an AI response is being generated.
class AiTypingDotsIndicator extends StatefulWidget {
  final bool compact;

  const AiTypingDotsIndicator({super.key, this.compact = false});

  @override
  State<AiTypingDotsIndicator> createState() => _AiTypingDotsIndicatorState();
}

class _AiTypingDotsIndicatorState extends State<AiTypingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotSize = widget.compact ? 4.5 : 8.0;
    final spacing = widget.compact ? 3.0 : 6.0;
    final bounceHeight = widget.compact ? 2.5 : 5.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value * 2 * math.pi) - (index * 0.9);
            final wave = (math.sin(phase) + 1) / 2; // 0.0 .. 1.0
            final dy = -bounceHeight * wave;
            final opacity = 0.35 + (0.65 * wave);
            final scale = 0.85 + (0.25 * wave);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: opacity,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Reveals AI-generated text progressively in word chunks (like Gemini / ChatGPT
/// streaming responses) when a new [animationId] is encountered, while keeping
/// accessibility semantics on the full text.
class AiChunkedText extends StatefulWidget {
  final String text;
  final String animationId;
  final Key? textKey;
  final TextStyle? style;

  const AiChunkedText({
    super.key,
    required this.text,
    required this.animationId,
    this.textKey,
    this.style,
  });

  @override
  State<AiChunkedText> createState() => _AiChunkedTextState();
}

class _AiChunkedTextState extends State<AiChunkedText> {
  static final Set<String> _completedAnimationIds = <String>{};

  Timer? _timer;
  late List<String> _chunks;
  int _visibleChunkCount = 0;

  @override
  void initState() {
    super.initState();
    _startOrCompleteAnimation();
  }

  @override
  void didUpdateWidget(covariant AiChunkedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationId != widget.animationId ||
        oldWidget.text != widget.text) {
      _startOrCompleteAnimation();
    }
  }

  void _startOrCompleteAnimation() {
    _timer?.cancel();
    _chunks = _splitIntoWordChunks(widget.text);

    if (_chunks.length <= 1 ||
        _completedAnimationIds.contains(widget.animationId)) {
      _visibleChunkCount = _chunks.length;
      return;
    }

    _visibleChunkCount = 1;
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleChunkCount++;
        if (_visibleChunkCount >= _chunks.length) {
          _visibleChunkCount = _chunks.length;
          _completedAnimationIds.add(widget.animationId);
          timer.cancel();
        }
      });
    });
  }

  static List<String> _splitIntoWordChunks(String input) {
    final words = input
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return <String>[input];
    }
    const wordsPerChunk = 3;
    final chunks = <String>[];
    for (var i = 0; i < words.length; i += wordsPerChunk) {
      final end = math.min(i + wordsPerChunk, words.length);
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _visibleChunkCount >= _chunks.length;
    final displayedText = isComplete
        ? widget.text
        : _chunks.take(_visibleChunkCount).join(' ');

    return Text(
      displayedText,
      key: widget.textKey,
      semanticsLabel: widget.text,
      style: widget.style,
    );
  }
}
