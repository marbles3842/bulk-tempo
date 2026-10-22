import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_state.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/gain_target/presentation/views/gain_target_view.dart';

const _savedTarget = GainTargetEntity(
  minWeeklyGainKg: 0.15,
  maxWeeklyGainKg: 0.25,
);

class _CatalogGainTargetViewModel extends GainTargetViewModel {
  _CatalogGainTargetViewModel(this._state);

  final GainTargetState _state;

  @override
  GainTargetState build() => _state;

  @override
  Future<void> loadTarget({
    bool showLoading = true,
    bool isRefresh = false,
  }) async {}

  @override
  void updateMinInput(String value) {}

  @override
  void updateMaxInput(String value) {}

  @override
  Future<void> saveTarget() async {}

  @override
  void clearMessages() {}

  @override
  void discardDraft() {}
}

Widget _gainTargetState(GainTargetState state) {
  return ProviderScope(
    overrides: [
      gainTargetViewModelProvider.overrideWith(
        () => _CatalogGainTargetViewModel(state),
      ),
    ],
    child: const SizedBox(
      height: 620,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.space3),
          child: GainTargetView(),
        ),
      ),
    ),
  );
}

Widget _stateExample(String label, Widget child) {
  return SizedBox(
    width: 440,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Catalog entry for the gain-target view's deterministic state matrix.
final gainTargetCategory = WidgetbookCategory(
  name: 'Gain Target',
  children: [
    WidgetbookComponent(
      name: 'GainTargetView',
      useCases: [
        WidgetbookUseCase(
          name: 'Kitchen Sink — State Matrix',
          builder: (context) {
            final locale = Localizations.localeOf(context);
            final loaded = GainTargetState(
              savedTarget: _savedTarget,
              minInput: '0.15',
              maxInput: '0.25',
              hasLoadedOnce: true,
            );
            final empty = GainTargetState(hasLoadedOnce: true);
            final error = GainTargetState(
              errorMessage: locale.languageCode == 'pl'
                  ? 'Nie udało się wczytać tygodniowego celu przyrostu wagi.'
                  : 'Unable to load the weekly gain target.',
            );
            final validation = loaded.copyWith(
              minInput: '0',
              minError: locale.languageCode == 'pl'
                  ? 'Wprowadź wartość większą od zera.'
                  : 'Enter a value greater than zero.',
              rangeError: locale.languageCode == 'pl'
                  ? 'Maksimum musi być większe od minimum.'
                  : 'Maximum must be greater than minimum.',
              isDirty: true,
            );
            final busy = loaded.copyWith(
              isSubmitting: true,
              pendingTarget: _savedTarget,
            );
            final loading = GainTargetState(isLoading: true);
            final successMessage = locale.languageCode == 'pl'
                ? 'Tygodniowy cel przyrostu wagi został pomyślnie zapisany'
                : 'Weekly gain target saved successfully';

            return LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth < 480
                    ? constraints.maxWidth
                    : 440.0;
                Widget example(String title, Widget child) => SizedBox(
                  width: cardWidth,
                  child: _stateExample(title, child),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hover and focus the controls to inspect their interactive states. '
                        'Hover: move the pointer over Save or Refresh. Focus-visible: tab to a control.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Wrap(
                        spacing: AppSpacing.space4,
                        runSpacing: AppSpacing.space4,
                        children: [
                          example('Default / saved', _gainTargetState(loaded)),
                          example('Empty / no target', _gainTargetState(empty)),
                          example('Loading', _gainTargetState(loading)),
                          example('Fetch error', _gainTargetState(error)),
                          example(
                            'Validation error',
                            _gainTargetState(validation),
                          ),
                          example('Disabled / busy', _gainTargetState(busy)),
                          example(
                            'Success feedback',
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.space3),
                              child: AppFeedbackBanner(
                                message: successMessage,
                                tone: AppFeedbackTone.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);
