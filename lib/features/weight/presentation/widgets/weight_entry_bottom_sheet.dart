import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_form_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_view_model.dart';

/// Modal bottom sheet for logging or updating a daily weight measurement.
class WeightEntryBottomSheet extends ConsumerStatefulWidget {
  const WeightEntryBottomSheet({super.key});

  /// Helper to present [WeightEntryBottomSheet] modally.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WeightEntryBottomSheet(),
    );
  }

  @override
  ConsumerState<WeightEntryBottomSheet> createState() =>
      _WeightEntryBottomSheetState();
}

class _WeightEntryBottomSheetState
    extends ConsumerState<WeightEntryBottomSheet> {
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final initialInput = ref.read(weightEntryViewModelProvider).weightInput;
    _weightController = TextEditingController(text: initialInput);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime currentDate) async {
    final now = DateTime.now();
    final firstAllowedDate = now.subtract(
      const Duration(days: WeightValidators.maxLookbackDays),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate.isAfter(now)
          ? now
          : (currentDate.isBefore(firstAllowedDate)
                ? firstAllowedDate
                : currentDate),
      firstDate: firstAllowedDate,
      lastDate: now,
    );

    if (picked != null) {
      ref.read(weightEntryViewModelProvider.notifier).onDateChanged(picked);
    }
  }

  void _showOverwriteDialog(
    BuildContext context,
    WeightEntryEntity? existingEntry,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final existingWeightText = existingEntry != null
            ? '${existingEntry.weightKg.toStringAsFixed(2)} kg'
            : 'an existing weight';

        return AlertDialog(
          key: const Key('overwrite_weight_dialog'),
          title: const Text('Overwrite Weight Entry?'),
          content: Text(
            'A weight of $existingWeightText is already recorded for this date. '
            'Do you want to replace it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref
                    .read(weightEntryViewModelProvider.notifier)
                    .cancelOverwriteConfirmation();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm_overwrite_weight_button'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref
                    .read(weightEntryViewModelProvider.notifier)
                    .submit(confirmOverwrite: true);
              },
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WeightEntryFormState>(weightEntryViewModelProvider, (
      previous,
      next,
    ) {
      if (next.requiresOverwriteConfirmation &&
          !(previous?.requiresOverwriteConfirmation ?? false)) {
        _showOverwriteDialog(context, next.existingEntryForDate);
      }

      if (next.status == FormStatus.success &&
          previous?.status != FormStatus.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight entry saved successfully')),
        );
      }
    });

    final formState = ref.watch(weightEntryViewModelProvider);
    final theme = Theme.of(context);
    final isSubmitting = formState.status == FormStatus.submitting;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Body Weight',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (formState.errorMessage != null) ...[
                Container(
                  key: const Key('weight_entry_error_banner'),
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
                          formState.errorMessage!,
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
                key: const Key('weight_input_field'),
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'e.g. 78.50',
                  suffixText: 'kg',
                  errorText: formState.weightError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                ),
                onChanged: (value) {
                  ref
                      .read(weightEntryViewModelProvider.notifier)
                      .onWeightChanged(value);
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('weight_date_picker_button'),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  WeekDateUtils.formatDayWithWeekday(formState.selectedDate),
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  side: BorderSide(
                    color: formState.dateError != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () => _pickDate(formState.selectedDate),
              ),
              if (formState.dateError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    formState.dateError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('save_weight_button'),
                onPressed: isSubmitting
                    ? null
                    : () {
                        ref
                            .read(weightEntryViewModelProvider.notifier)
                            .submit();
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Weight'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
