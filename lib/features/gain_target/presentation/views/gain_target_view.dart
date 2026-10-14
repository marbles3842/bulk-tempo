import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade700,
          ),
        );
        ref.read(gainTargetViewModelProvider.notifier).clearMessages();
      }

      if (next.saveErrorMessage != null &&
          next.saveErrorMessage != previous?.saveErrorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.saveErrorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(gainTargetViewModelProvider.notifier).clearMessages();
      }

      if (next.refreshErrorMessage != null &&
          next.refreshErrorMessage != previous?.refreshErrorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.refreshErrorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(gainTargetViewModelProvider.notifier).clearMessages();
      }
    });

    final state = ref.watch(gainTargetViewModelProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    context.l10n.gainTargetTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('gain_target_refresh_button'),
                  icon: state.isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: context.l10n.gainTargetRefreshTooltip,
                  onPressed: state.isSubmitting
                      ? null
                      : () => ref
                            .read(gainTargetViewModelProvider.notifier)
                            .loadTarget(showLoading: false, isRefresh: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
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
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('gain_target_retry_button'),
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.track_changes,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.gainTargetCurrentLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Text(
                  summaryText,
                  key: const Key('gain_target_summary'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: state.savedTarget != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('gain_target_min_field'),
          controller: _minController,
          enabled: !state.isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.minWeeklyGainLabel,
            hintText: '0.15',
            suffixText: context.l10n.kgPerWeekUnit,
            errorText: state.minError,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => ref
              .read(gainTargetViewModelProvider.notifier)
              .updateMinInput(value),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('gain_target_max_field'),
          controller: _maxController,
          enabled: !state.isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.maxWeeklyGainLabel,
            hintText: '0.25',
            suffixText: context.l10n.kgPerWeekUnit,
            errorText: state.effectiveMaxError,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => ref
              .read(gainTargetViewModelProvider.notifier)
              .updateMaxInput(value),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('gain_target_save_button'),
          onPressed: state.isSubmitting
              ? null
              : () =>
                    ref.read(gainTargetViewModelProvider.notifier).saveTarget(),
          child: Text(context.l10n.saveTargetButton),
        ),
        if (state.isSubmitting) ...[
          const SizedBox(height: 12),
          Row(
            key: const Key('gain_target_pending_indicator'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(context.l10n.gainTargetWaitingConfirmation),
            ],
          ),
        ],
      ],
    );
  }
}
