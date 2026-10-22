import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/gain_target/presentation/formatters/gain_target_formatter.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_state.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';

/// Form section embedded in the Profile tab for reading, editing, and replacing
/// the user's weekly weight gain target.
class GainTargetView extends ConsumerStatefulWidget {
  const GainTargetView({super.key});

  @override
  ConsumerState<GainTargetView> createState() => _GainTargetViewState();
}

class _GainTargetViewState extends ConsumerState<GainTargetView> {
  static const double _refreshIndicatorSize = 18.0;
  static const double _pendingIndicatorSize = 16.0;
  static const double _indicatorStrokeWidth = 2.0;
  static const int _fieldLabelMaxLines = 2;
  static const String _minWeeklyGainHint = '0.15';
  static const String _maxWeeklyGainHint = '0.25';

  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final GainTargetViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(gainTargetViewModelProvider.notifier);
    final initialState = ref.read(gainTargetViewModelProvider);
    _minController = TextEditingController(text: initialState.minInput);
    _maxController = TextEditingController(text: initialState.maxInput);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final current = ref.read(gainTargetViewModelProvider);
        if (!current.isSubmitting) {
          _viewModel.loadTarget(showLoading: current.savedTarget == null);
        }
      }
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (_viewModel.mounted) {
        _viewModel.discardDraft();
      }
    });
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GainTargetState>(gainTargetViewModelProvider, (previous, next) {
      if (!next.isDirty) {
        if (_minController.text != next.minInput) {
          _minController.text = next.minInput;
        }
        if (_maxController.text != next.maxInput) {
          _maxController.text = next.maxInput;
        }
      }

      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        final message =
            next.successMessage == 'Weekly gain target saved successfully'
            ? context.l10n.gainTargetSavedSuccess
            : next.successMessage!;
        AppFeedback.showSnackBar(
          context,
          message: message,
          tone: AppFeedbackTone.success,
        );
        ref.read(gainTargetViewModelProvider.notifier).clearMessages();
      }

      if (next.saveErrorMessage != null &&
          next.saveErrorMessage != previous?.saveErrorMessage) {
        AppFeedback.showSnackBar(
          context,
          message: next.saveErrorMessage!,
          tone: AppFeedbackTone.error,
        );
        ref.read(gainTargetViewModelProvider.notifier).clearMessages();
      }

      if (next.refreshErrorMessage != null &&
          next.refreshErrorMessage != previous?.refreshErrorMessage) {
        AppFeedback.showSnackBar(
          context,
          message: next.refreshErrorMessage!,
          tone: AppFeedbackTone.error,
        );
        ref.read(gainTargetViewModelProvider.notifier).clearMessages();
      }
    });

    final state = ref.watch(gainTargetViewModelProvider);

    return AppCard(
      title: context.l10n.gainTargetTitle,
      variant: AppCardVariant.outlined,
      margin: const EdgeInsets.all(AppSpacing.space1),
      headerTrailing: IconButton(
        key: const Key('gain_target_refresh_button'),
        icon: state.isRefreshing
            ? const SizedBox(
                width: _refreshIndicatorSize,
                height: _refreshIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: _indicatorStrokeWidth,
                ),
              )
            : Icon(AppIcons.resolve(context, AppIcon.retry)),
        tooltip: context.l10n.gainTargetRefreshTooltip,
        onPressed: state.isSubmitting
            ? null
            : () => ref
                  .read(gainTargetViewModelProvider.notifier)
                  .loadTarget(showLoading: false, isRefresh: true),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space6),
              child: Center(
                child: CircularProgressIndicator(
                  key: Key('gain_target_loading_indicator'),
                ),
              ),
            )
          else if (state.errorMessage != null)
            _buildErrorView(context, state.errorMessage!)
          else
            _buildFormView(context, state),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.cardPadding),
      child: Column(
        children: [
          Icon(
            AppIcons.resolve(context, AppIcon.error),
            size: AppIcons.normalSize,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppButton(
            key: const Key('gain_target_retry_button'),
            label: context.l10n.retry,
            variant: AppButtonVariant.primary,
            icon: AppIcon.retry,
            onPressed: () => ref
                .read(gainTargetViewModelProvider.notifier)
                .loadTarget(showLoading: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(BuildContext context, GainTargetState state) {
    final summaryText = state.savedTarget != null
        ? '${GainTargetFormatter.formatRange(state.savedTarget!, context.l10n.localeName)} ${context.l10n.kgPerWeekUnit}'
        : context.l10n.gainTargetNoTargetSet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: AppShape.smallRadius,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              final label = Text(
                context.l10n.gainTargetCurrentLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              );
              final summary = Text(
                summaryText,
                key: const Key('gain_target_summary'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: state.savedTarget != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              );
              final icon = Icon(
                AppIcons.resolve(context, AppIcon.target),
                size: AppIcons.compactSize,
                color: colorScheme.primary,
              );
              final useStackedText =
                  MediaQuery.textScalerOf(context).scale(1.0) >=
                      AppSpacing.enlargedTextScaleThreshold ||
                  constraints.maxWidth < AppSpacing.stackedSummaryBreakpoint;

              if (useStackedText) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.inlineGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label,
                          const SizedBox(height: AppSpacing.space1),
                          summary,
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.inlineGap),
                  label,
                  Expanded(child: summary),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppTextField(
          fieldKey: const Key('gain_target_min_field'),
          controller: _minController,
          label: context.l10n.minWeeklyGainLabel,
          labelMaxLines: _fieldLabelMaxLines,
          hint: _minWeeklyGainHint,
          suffixText: context.l10n.kgPerWeekUnit,
          errorText: state.minError,
          enabled: !state.isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => ref
              .read(gainTargetViewModelProvider.notifier)
              .updateMinInput(value),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppTextField(
          fieldKey: const Key('gain_target_max_field'),
          controller: _maxController,
          label: context.l10n.maxWeeklyGainLabel,
          labelMaxLines: _fieldLabelMaxLines,
          hint: _maxWeeklyGainHint,
          suffixText: context.l10n.kgPerWeekUnit,
          errorText: state.effectiveMaxError,
          enabled: !state.isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => ref
              .read(gainTargetViewModelProvider.notifier)
              .updateMaxInput(value),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppButton(
          key: const Key('gain_target_save_button'),
          label: context.l10n.saveTargetButton,
          isEnabled: !state.isSubmitting,
          onPressed: () =>
              ref.read(gainTargetViewModelProvider.notifier).saveTarget(),
        ),
        if (state.isSubmitting) ...[
          const SizedBox(height: AppSpacing.space3),
          Row(
            key: const Key('gain_target_pending_indicator'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: _pendingIndicatorSize,
                height: _pendingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: _indicatorStrokeWidth,
                ),
              ),
              const SizedBox(width: AppSpacing.inlineGap),
              Flexible(
                child: Text(
                  context.l10n.gainTargetWaitingConfirmation,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
