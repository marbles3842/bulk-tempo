import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_form_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_view_model.dart';

/// Modal bottom sheet for connecting or updating a user's Hevy API key.
class HevyKeyBottomSheet extends ConsumerStatefulWidget {
  const HevyKeyBottomSheet({super.key});

  /// Presents [HevyKeyBottomSheet] modally and resets the form state.
  static Future<bool?> show(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(hevyKeyViewModelProvider.notifier).reset();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HevyKeyBottomSheet(),
    );
  }

  @override
  ConsumerState<HevyKeyBottomSheet> createState() => _HevyKeyBottomSheetState();
}

class _HevyKeyBottomSheetState extends ConsumerState<HevyKeyBottomSheet> {
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(
      text: ref.read(hevyKeyViewModelProvider).rawKey,
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await ref
        .read(hevyKeyViewModelProvider.notifier)
        .submitKey();
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(hevyKeyViewModelProvider);
    final theme = Theme.of(context);
    final isSubmitting = formState.status == FormStatus.submitting;

    return Container(
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
                  context.l10n.connectHevyKeyTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.close,
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.connectHevyKeySubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (formState.submitErrorMessage != null) ...[
              Container(
                key: const Key('hevy_key_sheet_error_banner'),
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
                        formState.submitErrorMessage!,
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
              key: const Key('hevy_key_sheet_input_field'),
              controller: _keyController,
              enabled: !isSubmitting,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: context.l10n.hevyKeyInputLabel,
                hintText: context.l10n.hevyKeyInputHint,
                errorText: formState.validationError?.toLocalizedMessage(
                  context.l10n,
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              onChanged: (value) {
                ref.read(hevyKeyViewModelProvider.notifier).updateKey(value);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('hevy_key_sheet_save_button'),
              onPressed: isSubmitting ? null : _handleSubmit,
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
                  : Text(context.l10n.saveAndConnectButton),
            ),
          ],
        ),
      ),
    );
  }
}
