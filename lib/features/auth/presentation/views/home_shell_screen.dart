import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/gain_target/presentation/views/gain_target_view.dart';
import 'package:bulk_tempo/features/weight/presentation/views/weight_history_view.dart';

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
                'Welcome to Bulk Tempo',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                email ?? 'No email',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('home_go_to_weights_button'),
                icon: const Icon(Icons.monitor_weight),
                label: const Text('Go to Weights'),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('home_logout_button'),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, String? email) {
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
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
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
        body = _buildHomeTab(context, user?.email);
      case 1:
        body = const WeightHistoryView();
      case 2:
        body = _buildProfileTab(context, user?.email);
      default:
        body = _buildHomeTab(context, user?.email);
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
