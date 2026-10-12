import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_form_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_view_model.dart';

/// Modal bottom sheet for logging or updating a daily weight measurement.
class WeightEntryBottomSheet extends ConsumerStatefulWidget {
  final WeightEntryEntity? existingEntry;

  const WeightEntryBottomSheet({super.key, this.existingEntry});

  /// Helper to present [WeightEntryBottomSheet] modally.
  static Future<void> show(
    BuildContext context, {
    WeightEntryEntity? existingEntry,
  }) {
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(weightEntryViewModelProvider.notifier);
    if (existingEntry != null) {
      notifier.initializeEdit(existingEntry);
    } else {
      notifier.initializeAdd();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          WeightEntryBottomSheet(existingEntry: existingEntry),
    );
  }

  @override
  ConsumerState<WeightEntryBottomSheet> createState() =>
      _WeightEntryBottomSheetState();
}

class _WeightEntryBottomSheetState
    extends ConsumerState<WeightEntryBottomSheet> {
  late final TextEditingController _weightController;
  double _dragDistance = 0.0;
  bool _forceDismiss = false;
  bool _dismissPromptOpen = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;
    final initialInput = existing != null
        ? existing.weightKg.toStringAsFixed(2)
        : ref.read(weightEntryViewModelProvider).weightInput;
    _weightController = TextEditingController(text: initialInput);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(weightEntryViewModelProvider);
      final notifier = ref.read(weightEntryViewModelProvider.notifier);
      if (widget.existingEntry != null) {
        if (current.originalEntry != widget.existingEntry) {
          notifier.initializeEdit(widget.existingEntry!);
        }
      } else if (current.isEdit) {
        notifier.initializeAdd();
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime currentDate) async {
    final now = DateTime.now();
    final firstAllowedDate = DateTime(
      now.year,
      now.month,
      now.day - WeightValidators.maxLookbackDays,
    );

    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
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

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WeightEntryFormState formState,
  ) {
    final original = formState.originalEntry;
    if (original == null) return;

    final formattedDate = WeekDateUtils.formatDayWithWeekday(original.date);
    final weightText = '${original.weightKg.toStringAsFixed(2)} kg';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('delete_confirmation_dialog'),
          title: const Text('Delete Weight Entry?'),
          content: Text(
            'Permanently delete the measurement of $weightText recorded on $formattedDate?',
          ),
          actions: [
            TextButton(
              key: const Key('cancel_delete_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm_delete_button'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(weightEntryViewModelProvider.notifier).delete();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDiscardDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('discard_changes_dialog'),
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Do you want to discard them or keep editing?',
          ),
          actions: [
            TextButton(
              key: const Key('keep_editing_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              key: const Key('discard_changes_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDismissRequest() async {
    if (_forceDismiss || _dismissPromptOpen) return;
    final formState = ref.read(weightEntryViewModelProvider);
    if (formState.status == FormStatus.submitting) {
      // While submitting, disable inputs, Save, Delete, close, Back, outside-tap and swipe dismissal
      return;
    }

    if (formState.isEdit && formState.isDirty) {
      _dismissPromptOpen = true;
      final bool? shouldDiscard;
      try {
        shouldDiscard = await _showDiscardDialog(context);
      } finally {
        _dismissPromptOpen = false;
      }
      if (shouldDiscard == true && mounted) {
        setState(() {
          _forceDismiss = true;
        });
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        setState(() {
          _forceDismiss = true;
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      final previousUserId = previous?.user?.id;
      final nextUserId = next.user?.id;
      if (previousUserId != null && previousUserId != nextUserId) {
        if (mounted) {
          setState(() {
            _forceDismiss = true;
          });
          Navigator.of(context).pop();
        }
      }
    });

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
        final currentUserId = ref.read(authViewModelProvider).user?.id;
        if (next.openingUserId != null && currentUserId != next.openingUserId) {
          return;
        }
        if (mounted) {
          setState(() {
            _forceDismiss = true;
          });
          Navigator.of(context).pop();
          final message = next.outcome == WeightEntryOutcome.deleted
              ? 'Weight entry deleted successfully'
              : 'Weight entry saved successfully';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              key: const Key('weight_entry_success_snackbar'),
              content: Text(message),
            ),
          );
        }
      }
    });

    final formState = ref.watch(weightEntryViewModelProvider);
    final theme = Theme.of(context);
    final isSubmitting = formState.status == FormStatus.submitting;
    final bool canDirectPop =
        _forceDismiss ||
        (!isSubmitting && (!formState.isEdit || !formState.isDirty));

    return PopScope(
      canPop: canDirectPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleDismissRequest();
      },
      child: Material(
        color: Colors.transparent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is OverscrollNotification &&
                notification.overscroll < -20) {
              _handleDismissRequest();
              return true;
            }
            if (notification is ScrollUpdateNotification &&
                notification.metrics.pixels <= 0 &&
                (notification.scrollDelta ?? 0) < -20) {
              _handleDismissRequest();
              return true;
            }
            return false;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (_) {
              _dragDistance = 0.0;
            },
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! > 0) {
                _dragDistance += details.primaryDelta!;
              }
            },
            onVerticalDragEnd: (details) {
              if (_dragDistance > 100 || (details.primaryVelocity ?? 0) > 250) {
                _handleDismissRequest();
              }
              _dragDistance = 0.0;
            },
            onVerticalDragCancel: () {
              _dragDistance = 0.0;
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                          formState.isEdit
                              ? 'Edit Weight Entry'
                              : 'Log Body Weight',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: isSubmitting
                              ? null
                              : () => _handleDismissRequest(),
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
                        WeekDateUtils.formatDayWithWeekday(
                          formState.selectedDate,
                        ),
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
                      onPressed: (isSubmitting || formState.isEdit)
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
                      child: isSubmitting && formState.isSaving
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
                    if (formState.isEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const Key('delete_weight_button'),
                        onPressed: isSubmitting
                            ? null
                            : () => _showDeleteConfirmationDialog(
                                context,
                                formState,
                              ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSubmitting && formState.isDeleting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.error,
                                ),
                              )
                            : const Text('Delete Entry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
