import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.logoutDialogTitle),
          content: Text(context.l10n.logoutDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              key: const Key('confirm_logout_button'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authViewModelProvider.notifier).signOut();
              },
              child: Text(context.l10n.logoutDialogConfirm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeTab(BuildContext context, String? email) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 72),
              const SizedBox(height: 16),
              Text(
                context.l10n.homeWelcomeTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email ?? context.l10n.noEmail,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('home_go_to_weights_button'),
                icon: const Icon(Icons.monitor_weight),
                label: Text(context.l10n.homeGoToWeights),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                key: const Key('home_go_to_workouts_button'),
                icon: const Icon(Icons.fitness_center),
                label: Text(context.l10n.homeGoToWorkouts),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('home_logout_button'),
                icon: const Icon(Icons.logout),
                label: Text(context.l10n.logoutButton),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, String? email) {
    final workoutState = ref.watch(workoutProgressViewModelProvider);
    final maskedApiKey = workoutState.maskedApiKey;
    final currentLocale = ref.watch(localeProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_outline, size: 72),
            const SizedBox(height: 16),
            Text(
              context.l10n.profileTitle,
              key: const Key('profile_heading'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              email ?? context.l10n.noEmail,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const GainTargetView(),
            const SizedBox(height: 24),
            Card(
              key: const Key('profile_hevy_card'),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.hevyIntegrationTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.connectionStatusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            key: const Key(
                              'profile_connect_or_update_hevy_key_button',
                            ),
                            onPressed: () => HevyKeyBottomSheet.show(context),
                            child: Text(
                              maskedApiKey != null
                                  ? context.l10n.updateKeyButton
                                  : context.l10n.connectHevyKeyButton,
                            ),
                          ),
                        ),
                        if (maskedApiKey != null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            key: const Key(
                              'profile_disconnect_hevy_key_button',
                            ),
                            onPressed: () {
                              ref
                                  .read(
                                    workoutProgressViewModelProvider.notifier,
                                  )
                                  .disconnectApiKey();
                            },
                            child: Text(context.l10n.disconnectButton),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLanguageCard(context, currentLocale),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              key: const Key('profile_logout_button'),
              icon: const Icon(Icons.logout),
              label: Text(context.l10n.logoutButton),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, Locale? currentLocale) {
    return Card(
      key: const Key('profile_language_card'),
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
              children: [
                Icon(
                  Icons.language,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.languageLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                key: const Key('profile_language_selector'),
                segments: [
                  ButtonSegment<String>(
                    value: LocaleConstants.system,
                    label: Text(context.l10n.languageSystem),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = _buildHomeTab(context, user?.email);
      case 1:
        body = const WeightHistoryView();
      case 2:
        body = const WorkoutProgressView();
      case 3:
        body = _buildProfileTab(context, user?.email);
      default:
        body = _buildHomeTab(context, user?.email);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('home_app_bar_logout_button'),
            icon: const Icon(Icons.logout),
            tooltip: context.l10n.logoutButton,
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
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
        destinations: [
          NavigationDestination(
            key: const Key('nav_home_tab'),
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.l10n.navHome,
          ),
          NavigationDestination(
            key: const Key('nav_weights_tab'),
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: const Icon(Icons.monitor_weight),
            label: context.l10n.navWeights,
          ),
          NavigationDestination(
            key: const Key('nav_workouts_tab'),
            icon: const Icon(Icons.fitness_center_outlined),
            selectedIcon: const Icon(Icons.fitness_center),
            label: context.l10n.navWorkouts,
          ),
          NavigationDestination(
            key: const Key('nav_profile_tab'),
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
