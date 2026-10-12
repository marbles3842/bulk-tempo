import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('confirm_logout_button'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authViewModelProvider.notifier).signOut();
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab(BuildContext context, String? email) {
    final workoutState = ref.watch(workoutProgressViewModelProvider);
    final maskedApiKey = workoutState.maskedApiKey;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_outline, size: 72),
            const SizedBox(height: 16),
            Text(
              'Profile',
              key: const Key('profile_heading'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              email ?? 'No email',
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
                          'Hevy Integration',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connection status:',
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
                        'Not connected',
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
                                  ? 'Update Key'
                                  : 'Connect Hevy Key',
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
                            child: const Text('Disconnect'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              key: const Key('profile_logout_button'),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              onPressed: () => _showLogoutDialog(context),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Tempo'),
        actions: [
          IconButton(
            key: const Key('home_app_bar_logout_button'),
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
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
        destinations: const [
          NavigationDestination(
            key: Key('nav_home_tab'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            key: Key('nav_weights_tab'),
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Weights',
          ),
          NavigationDestination(
            key: Key('nav_workouts_tab'),
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          NavigationDestination(
            key: Key('nav_profile_tab'),
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
