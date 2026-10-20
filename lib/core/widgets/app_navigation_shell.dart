import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';

/// Navigation item description for [AppNavigationShell].
@immutable
class AppNavigationDestinationItem {
  const AppNavigationDestinationItem({
    this.key,
    required this.label,
    required this.icon,
    this.badgeText,
  });

  /// Optional [Key] assigned to the destination widget or icon.
  final Key? key;

  /// Human-readable label for the destination.
  final String label;

  /// Semantic [AppIcon] displayed for this destination.
  final AppIcon icon;

  /// Optional badge label text (e.g. notification count or status indicator).
  final String? badgeText;
}

/// Action item displayed in the top app bar/toolbar of [AppNavigationShell].
@immutable
class AppToolbarAction {
  const AppToolbarAction({
    this.key,
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  /// Optional [Key] assigned to the action button widget.
  final Key? key;

  /// Accessibility tooltip text.
  final String tooltip;

  /// Semantic [AppIcon] for the action.
  final AppIcon icon;

  /// Callback when the action is pressed.
  final VoidCallback? onPressed;
}

/// Top-level platform-adaptive and responsive navigation shell.
///
/// Dispatches to:
/// - Material 3: responsive layout with [NavigationBar] (<840px width) or
///   leading [NavigationRail] (>=840px width), standard [AppBar], and FAB.
/// - Classic Cupertino (iOS 15–25): [Scaffold] with [CupertinoNavigationBar],
///   [CupertinoTabBar], and FAB support.
/// - Cupertino Liquid Glass (iOS 26+): [AdaptiveScaffold] with native
///   [AdaptiveAppBar] (`useNativeToolbar: true`), [AdaptiveBottomNavigationBar],
///   and Liquid Glass blur enabled (`enableBlur: true`).
class AppNavigationShell extends ConsumerWidget {
  const AppNavigationShell({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.toolbarActions = const [],
    this.floatingActionButton,
    required this.body,
  });

  /// Screen or section title displayed in the top bar.
  final String title;

  /// List of navigation destinations.
  final List<AppNavigationDestinationItem> destinations;

  /// Currently selected tab/destination index.
  final int selectedIndex;

  /// Callback when a destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Optional action buttons displayed in the trailing area of the top bar.
  final List<AppToolbarAction> toolbarActions;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Main content body widget.
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = PresentationCapabilities.resolve(context);

    switch (capabilities.platformMode) {
      case AdaptivePlatformMode.material:
        return _buildMaterial(context);
      case AdaptivePlatformMode.cupertinoClassic:
        return _buildCupertinoClassic(context);
      case AdaptivePlatformMode.cupertinoLiquidGlass:
        return _buildCupertinoLiquidGlass(context);
    }
  }

  Widget _buildMaterial(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExpanded =
            constraints.maxWidth >= AppSpacing.expandedBreakpoint;

        final appBar = AppBar(
          title: Text(title),
          actions: toolbarActions.map((action) {
            return IconButton(
              key: action.key,
              tooltip: action.tooltip,
              icon: Icon(AppIcons.material(action.icon)),
              onPressed: action.onPressed,
            );
          }).toList(),
        );

        if (isExpanded) {
          return Scaffold(
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations.map((dest) {
                    final icon = Icon(
                      AppIcons.material(dest.icon, selected: false),
                    );
                    final selectedIcon = Icon(
                      AppIcons.material(dest.icon, selected: true),
                    );
                    return NavigationRailDestination(
                      icon: KeyedSubtree(
                        key: dest.key,
                        child: dest.badgeText != null
                            ? Badge(label: Text(dest.badgeText!), child: icon)
                            : icon,
                      ),
                      selectedIcon: dest.badgeText != null
                          ? Badge(
                              label: Text(dest.badgeText!),
                              child: selectedIcon,
                            )
                          : selectedIcon,
                      label: Text(dest.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations.map((dest) {
              final icon = Icon(AppIcons.material(dest.icon, selected: false));
              final selectedIcon = Icon(
                AppIcons.material(dest.icon, selected: true),
              );
              return NavigationDestination(
                key: dest.key,
                icon: dest.badgeText != null
                    ? Badge(label: Text(dest.badgeText!), child: icon)
                    : icon,
                selectedIcon: dest.badgeText != null
                    ? Badge(label: Text(dest.badgeText!), child: selectedIcon)
                    : selectedIcon,
                label: dest.label,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCupertinoClassic(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: Text(title),
        trailing: toolbarActions.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: toolbarActions.map((action) {
                  return CupertinoButton(
                    key: action.key,
                    padding: EdgeInsets.zero,
                    onPressed: action.onPressed,
                    child: Semantics(
                      label: action.tooltip,
                      child: Icon(
                        AppIcons.cupertino(action.icon),
                        size: AppIcons.compactSize,
                      ),
                    ),
                  );
                }).toList(),
              )
            : null,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        items: destinations.map((dest) {
          Widget iconWidget = Icon(
            AppIcons.cupertino(dest.icon, selected: false),
            key: dest.key,
          );
          Widget activeIconWidget = Icon(
            AppIcons.cupertino(dest.icon, selected: true),
          );
          if (dest.badgeText != null) {
            iconWidget = Badge(label: Text(dest.badgeText!), child: iconWidget);
            activeIconWidget = Badge(
              label: Text(dest.badgeText!),
              child: activeIconWidget,
            );
          }
          return BottomNavigationBarItem(
            icon: iconWidget,
            activeIcon: activeIconWidget,
            label: dest.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCupertinoLiquidGlass(BuildContext context) {
    return AdaptiveScaffold(
      enableBlur: true,
      floatingActionButton: floatingActionButton,
      appBar: AdaptiveAppBar(
        title: title,
        useNativeToolbar: true,
        actions: toolbarActions.where((action) => action.onPressed != null).map(
          (action) {
            return AdaptiveAppBarAction(
              iosSymbol: AppIcons.sfSymbol(action.icon),
              icon: AppIcons.cupertino(action.icon),
              iconWidget: action.key != null
                  ? KeyedSubtree(
                      key: action.key,
                      child: Icon(AppIcons.cupertino(action.icon)),
                    )
                  : null,
              label: action.tooltip,
              onPressed: action.onPressed!,
            );
          },
        ).toList(),
      ),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: selectedIndex,
        onTap: onDestinationSelected,
        items: destinations.map((dest) {
          return AdaptiveNavigationDestination(
            icon: AppIcons.sfSymbol(dest.icon, selected: false),
            selectedIcon: AppIcons.sfSymbol(dest.icon, selected: true),
            label: dest.label,
            badgeText: dest.badgeText,
          );
        }).toList(),
      ),
      body: body,
    );
  }
}
