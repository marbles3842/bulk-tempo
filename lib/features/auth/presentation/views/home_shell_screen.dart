import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:bulk_tempo/features/gain_target/presentation/views/gain_target_view.dart';
import 'package:bulk_tempo/features/weight/presentation/views/weight_history_view.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/views/workout_progress_view.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/hevy_key_bottom_sheet.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _selectedIndex = 0;

  void _showLogoutDialog(BuildContext context) {
    AppDialog.showConfirm<bool>(
      context,
      dialogKey: const Key('logout_confirm_dialog'),
      title: context.l10n.logoutDialogTitle,
      message: context.l10n.logoutDialogContent,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.logoutDialogConfirm,
      confirmButtonKey: const Key('confirm_logout_button'),
      isDestructive: true,
      onConfirm: () => ref.read(authViewModelProvider.notifier).signOut(),
    );
  }

  Widget _buildHevyCard(BuildContext context, String? maskedApiKey) {
    return AppCard(
      cardKey: const Key('profile_hevy_card'),
      variant: AppCardVariant.outlined,
      title: context.l10n.hevyIntegrationTitle,
      leadingIcon: AppIcon.workout,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow =
              constraints.maxWidth < AppSpacing.stackedSummaryBreakpoint;
          final textScaler = MediaQuery.textScalerOf(context);
          final isEnlarged =
              textScaler.scale(1.0) >= AppSpacing.enlargedTextScaleThreshold;
          final shouldStack = isNarrow || isEnlarged;

          final connectOrUpdateButton = AppButton(
            key: const Key('profile_connect_or_update_hevy_key_button'),
            label: maskedApiKey != null
                ? context.l10n.updateKeyButton
                : context.l10n.connectHevyKeyButton,
            variant: AppButtonVariant.tonal,
            expand: true,
            onPressed: () => HevyKeyBottomSheet.show(context),
          );

          final disconnectButton = maskedApiKey != null
              ? AppButton(
                  key: const Key('profile_disconnect_hevy_key_button'),
                  label: context.l10n.disconnectButton,
                  variant: AppButtonVariant.outlined,
                  expand: shouldStack,
                  onPressed: () {
                    ref
                        .read(workoutProgressViewModelProvider.notifier)
                        .disconnectApiKey();
                  },
                )
              : null;

          final Widget buttons;
          if (shouldStack) {
            buttons = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                connectOrUpdateButton,
                if (disconnectButton != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  disconnectButton,
                ],
              ],
            );
          } else {
            buttons = Row(
              children: [
                Expanded(child: connectOrUpdateButton),
                if (disconnectButton != null) ...[
                  const SizedBox(width: AppSpacing.space2),
                  disconnectButton,
                ],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.connectionStatusLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              if (maskedApiKey != null)
                Text(
                  maskedApiKey,
                  key: const Key('profile_hevy_masked_key'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  context.l10n.hevyNotConnected,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.space4),
              buttons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, Locale currentLocale) {
    final capabilities = PresentationCapabilities.resolve(context);
    final isMaterial =
        capabilities.platformMode == AdaptivePlatformMode.material;

    final Widget selector;
    if (isMaterial) {
      selector = SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          key: const Key('profile_language_selector'),
          segments: [
            ButtonSegment<String>(
              value: LocaleConstants.english,
              label: Text(context.l10n.languageEnglish),
            ),
            ButtonSegment<String>(
              value: LocaleConstants.polish,
              label: Text(context.l10n.languagePolish),
            ),
          ],
          selected: {LocaleConstants.toSelectionCode(currentLocale)},
          onSelectionChanged: (newSelection) {
            final selectedLocale = LocaleConstants.fromSelectionCode(
              newSelection.first,
            );
            ref.read(localeProvider.notifier).setLocale(selectedLocale);
          },
        ),
      );
    } else {
      selector = SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<String>(
          key: const Key('profile_language_selector'),
          groupValue: LocaleConstants.toSelectionCode(currentLocale),
          children: {
            LocaleConstants.english: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Text(context.l10n.languageEnglish),
            ),
            LocaleConstants.polish: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Text(context.l10n.languagePolish),
            ),
          },
          onValueChanged: (value) {
            if (value != null) {
              final selectedLocale = LocaleConstants.fromSelectionCode(value);
              ref.read(localeProvider.notifier).setLocale(selectedLocale);
            }
          },
        ),
      );
    }

    return AppCard(
      cardKey: const Key('profile_language_card'),
      variant: AppCardVariant.outlined,
      title: context.l10n.languageLabel,
      leadingIcon: AppIcon.language,
      child: selector,
    );
  }

  Widget _buildProfileTab(BuildContext context, String? email) {
    final workoutState = ref.watch(workoutProgressViewModelProvider);
    final maskedApiKey = workoutState.maskedApiKey;
    final currentLocale = ref.watch(localeProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pageInsetWide),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.dashboardMaxWidth,
            ),
            child: Column(
              children: [
                Icon(
                  AppIcons.resolve(context, AppIcon.profile),
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  context.l10n.profileTitle,
                  key: const Key('profile_heading'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  email ?? context.l10n.noEmail,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const GainTargetView(),
                const SizedBox(height: AppSpacing.sectionGap),
                _buildHevyCard(context, maskedApiKey),
                const SizedBox(height: AppSpacing.sectionGap),
                _buildLanguageCard(context, currentLocale),
                const SizedBox(height: AppSpacing.space8),
                AppButton(
                  key: const Key('profile_logout_button'),
                  label: context.l10n.logoutButton,
                  icon: AppIcon.logout,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppFeedback.showSnackBar(
          context,
          message: next.errorMessage!,
          tone: AppFeedbackTone.error,
        );
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = const DashboardView();
      case 1:
        body = const WeightHistoryView();
      case 2:
        body = const WorkoutProgressView();
      case 3:
        body = _buildProfileTab(context, user?.email);
      default:
        body = const DashboardView();
    }

    return AppNavigationShell(
      title: context.l10n.appTitle,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 3) {
          ref
              .read(workoutProgressViewModelProvider.notifier)
              .ensureInitialized();
        }
      },
      toolbarActions: [
        AppToolbarAction(
          key: const Key('home_app_bar_logout_button'),
          tooltip: context.l10n.logoutButton,
          icon: AppIcon.logout,
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
      destinations: [
        AppNavigationDestinationItem(
          key: const Key('nav_home_tab'),
          label: context.l10n.navHome,
          icon: AppIcon.home,
        ),
        AppNavigationDestinationItem(
          key: const Key('nav_weights_tab'),
          label: context.l10n.navWeights,
          icon: AppIcon.weight,
        ),
        AppNavigationDestinationItem(
          key: const Key('nav_workouts_tab'),
          label: context.l10n.navWorkouts,
          icon: AppIcon.workout,
        ),
        AppNavigationDestinationItem(
          key: const Key('nav_profile_tab'),
          label: context.l10n.navProfile,
          icon: AppIcon.profile,
        ),
      ],
      body: body,
    );
  }
}
