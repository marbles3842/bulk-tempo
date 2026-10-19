// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';

PresentationCapabilities _capabilitiesForMode(AdaptivePlatformMode mode) {
  switch (mode) {
    case AdaptivePlatformMode.material:
      return const PresentationCapabilities(
        targetPlatform: TargetPlatform.android,
      );
    case AdaptivePlatformMode.cupertinoClassic:
      return const PresentationCapabilities(
        targetPlatform: TargetPlatform.iOS,
        iosMajorVersion: 18,
        supportsNativeIosViews: false,
      );
    case AdaptivePlatformMode.cupertinoLiquidGlass:
      return const PresentationCapabilities(
        targetPlatform: TargetPlatform.iOS,
        iosMajorVersion: 26,
        supportsNativeIosViews: true,
        reduceTransparency: false,
      );
  }
}

Widget _wrapAdaptivePlatform(
  BuildContext context,
  AdaptivePlatformMode mode,
  Widget child,
) {
  final capabilities = _capabilitiesForMode(mode);
  final theme = Theme.of(context);
  final targetPlatform = mode == AdaptivePlatformMode.material
      ? TargetPlatform.android
      : TargetPlatform.iOS;

  return ProviderScope(
    overrides: [
      presentationCapabilitiesOverrideProvider.overrideWithValue(capabilities),
    ],
    child: Theme(
      data: theme.copyWith(platform: targetPlatform),
      child: CupertinoTheme(
        data: AppTheme.cupertinoFromMaterial(theme),
        child: child,
      ),
    ),
  );
}

AdaptivePlatformMode _readPlatformKnob(BuildContext context) {
  try {
    return context.knobs.object.dropdown<AdaptivePlatformMode>(
      label: 'Platform Mode',
      options: AdaptivePlatformMode.values,
      initialOption: AdaptivePlatformMode.material,
      labelBuilder: (mode) => switch (mode) {
        AdaptivePlatformMode.material => 'Material 3 (Android)',
        AdaptivePlatformMode.cupertinoClassic =>
          'Cupertino Classic (iOS 15–25)',
        AdaptivePlatformMode.cupertinoLiquidGlass =>
          'Cupertino Liquid Glass (iOS 26+)',
      },
    );
  } catch (_) {
    return AdaptivePlatformMode.material;
  }
}

/// Category containing all overlay, dialog, sheet, and navigation shell use cases.
final overlaysAndShellCategory = WidgetbookCategory(
  name: 'Overlays & Shell',
  children: [
    WidgetbookComponent(
      name: 'AppDialog',
      useCases: [
        WidgetbookUseCase(
          name: 'Confirmation & Destructive Dialogs',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppDialog Alert & Confirmation',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Platform-adaptive dialogs dispatching to Material 3 AlertDialog, CupertinoAlertDialog, or AdaptiveAlertDialog.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    AppCard(
                      title: 'Confirmation Dialog (Non-Destructive)',
                      subtitle:
                          'Used for discarding unsaved forms or leaving dirty screens',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Title: "Discard Unsaved Changes?"\nMessage: "You have unsaved changes in this weigh-in entry. Are you sure you want to discard them?"',
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          AppButton(
                            label: 'Trigger Confirmation Dialog',
                            variant: AppButtonVariant.primary,
                            onPressed: () async {
                              final result = await AppDialog.showConfirm<bool>(
                                context,
                                title: 'Discard Unsaved Changes?',
                                message:
                                    'You have unsaved changes in this weigh-in entry. Are you sure you want to discard them?',
                                cancelLabel: 'Keep Editing',
                                confirmLabel: 'Discard',
                                isDestructive: false,
                                cancelResult: false,
                                confirmResult: true,
                              );
                              if (context.mounted && result != null) {
                                AppFeedback.showSnackBar(
                                  context,
                                  message:
                                      'Dialog resolved: ${result ? "Discarded" : "Kept editing"}',
                                  tone: AppFeedbackTone.info,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    AppCard(
                      title: 'Destructive Action Dialog',
                      subtitle:
                          'Used for permanent deletions and irreversible operations',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Title: "Delete Weight Entry?"\nMessage: "This action cannot be undone. All rolling averages calculated from this date will be adjusted."',
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          AppButton(
                            label: 'Trigger Destructive Dialog',
                            variant: AppButtonVariant.destructive,
                            icon: AppIcon.delete,
                            onPressed: () async {
                              final result = await AppDialog.showConfirm<bool>(
                                context,
                                title: 'Delete Weight Entry?',
                                message:
                                    'This action cannot be undone. All rolling averages calculated from this date will be adjusted.',
                                cancelLabel: 'Cancel',
                                confirmLabel: 'Delete Entry',
                                isDestructive: true,
                                cancelResult: false,
                                confirmResult: true,
                              );
                              if (context.mounted && result != null) {
                                AppFeedback.showSnackBar(
                                  context,
                                  message:
                                      'Dialog resolved: ${result ? "Deleted" : "Cancelled"}',
                                  tone: result
                                      ? AppFeedbackTone.error
                                      : AppFeedbackTone.info,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'AppSheetFrame',
      useCases: [
        WidgetbookUseCase(
          name: 'Standard Form Sheet',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            final keyboardInset = context.knobs.double.slider(
              label: 'Simulated Keyboard Inset (px)',
              initialValue: 0.0,
              min: 0.0,
              max: 320.0,
              divisions: 8,
            );

            final isDirty = context.knobs.boolean(
              label: 'Simulate Dirty Form (canPop: false)',
              initialValue: false,
            );

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppSheetFrame Standard Form Sheet',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Modal bottom sheet frame featuring standard 24px top radii, surfaceContainerHigh container, keyboard clearance, and dismissal guards.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    AppButton(
                      label: 'Open Modal Form Sheet',
                      variant: AppButtonVariant.primary,
                      icon: AppIcon.addMeasurement,
                      onPressed: () {
                        AppSheetFrame.show<void>(
                          context,
                          builder: (sheetContext) => AppSheetFrame(
                            title: 'Log Morning Weight',
                            subtitle: 'Today, Oct 18, 2026',
                            summaryText: 'Record before eating or drinking',
                            canPop: !isDirty,
                            onDismissRequested: isDirty
                                ? () async {
                                    final discard =
                                        await AppDialog.showConfirm<bool>(
                                          sheetContext,
                                          title: 'Discard Weigh-In?',
                                          message:
                                              'You have entered weight data. Discard without saving?',
                                          cancelLabel: 'Keep Editing',
                                          confirmLabel: 'Discard',
                                          isDestructive: true,
                                          confirmResult: true,
                                          cancelResult: false,
                                        );
                                    if (discard == true &&
                                        sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  }
                                : null,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppTextField(
                                  label: 'Body Weight',
                                  hint: '82.50',
                                  suffixText: 'kg',
                                  prefixIcon: AppIcon.weight,
                                ),
                                const SizedBox(height: AppSpacing.space4),
                                AppButton(
                                  label: 'Save Measurement',
                                  expand: true,
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    Text(
                      'Inline Frame Geometry & Keyboard Clearance Preview:',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          viewInsets: EdgeInsets.only(bottom: keyboardInset),
                        ),
                        child: AppSheetFrame(
                          title: 'Inline Preview: Log Body Weight',
                          subtitle: 'Simulated bottom sheet layout',
                          summaryText:
                              'Top radius 24px • Bottom padding with ${keyboardInset.toInt()}px keyboard inset',
                          canPop: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const AppTextField(
                                label: 'Weight Input',
                                hint: '82.50',
                                suffixText: 'kg',
                                prefixIcon: AppIcon.weight,
                              ),
                              const SizedBox(height: AppSpacing.space3),
                              AppButton(
                                label: 'Submit Entry',
                                expand: true,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Draggable Detail Sheet',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppSheetFrame Draggable Detail Sheet',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Draggable sheet utilizing DraggableScrollableSheet with initial (0.75), min (0.45), and max (0.92) child sizes.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    AppButton(
                      label: 'Open Draggable Workout Sheet',
                      variant: AppButtonVariant.primary,
                      icon: AppIcon.workout,
                      onPressed: () {
                        AppSheetFrame.show<void>(
                          context,
                          builder: (sheetContext) => AppSheetFrame(
                            title: 'Weekly Workout Breakdown',
                            subtitle: '4 logged sessions this week',
                            summaryText:
                                'Total volume: 8,420 kg • 18 total sets',
                            isDraggable: true,
                            initialChildSize: 0.75,
                            minChildSize: 0.45,
                            maxChildSize: 0.92,
                            scrollableBuilder: (ctx, scrollController) {
                              final workouts = [
                                (
                                  'Chest & Triceps',
                                  'Mon, Oct 13 • 4 exercises • 2,450 kg',
                                ),
                                (
                                  'Back & Biceps',
                                  'Wed, Oct 15 • 5 exercises • 2,800 kg',
                                ),
                                (
                                  'Legs & Calves',
                                  'Fri, Oct 17 • 4 exercises • 3,170 kg',
                                ),
                                (
                                  'Shoulders & Arms',
                                  'Sat, Oct 18 • 4 exercises • 1,980 kg',
                                ),
                              ];

                              return ListView.separated(
                                controller: scrollController,
                                itemCount: workouts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.space2),
                                itemBuilder: (_, i) => AppCard(
                                  variant: AppCardVariant.outlined,
                                  title: workouts[i].$1,
                                  subtitle: workouts[i].$2,
                                  leadingIcon: AppIcon.workout,
                                  child: const Text(
                                    'Routine imported from Hevy with completed RPE ratings.',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'AppNavigationShell',
      useCases: [
        WidgetbookUseCase(
          name: 'Responsive Navigation Shell (4 Destinations)',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            final previewWidth = context.knobs.object.segmented<double>(
              label: 'Viewport Width',
              options: const [375.0, 720.0, 960.0],
              initialOption: 375.0,
              labelBuilder: (w) => switch (w) {
                375.0 => 'Compact (<600px)',
                720.0 => 'Medium (600–839px)',
                _ => 'Expanded (>=840px Rail)',
              },
            );

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppNavigationShell Responsive Adaptation',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Responsive top-level navigation adapting to compact (<600px) NavigationBar / CupertinoTabBar, '
                      'medium (600–839px) NavigationBar, and expanded (>=840px) leading NavigationRail.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Center(
                      child: Container(
                        width: previewWidth,
                        height: 560,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _NavigationShellDemo(previewWidth: previewWidth),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

class _NavigationShellDemo extends StatefulWidget {
  const _NavigationShellDemo({required this.previewWidth});

  final double previewWidth;

  @override
  State<_NavigationShellDemo> createState() => _NavigationShellDemoState();
}

class _NavigationShellDemoState extends State<_NavigationShellDemo> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = const [
      AppNavigationDestinationItem(label: 'Dashboard', icon: AppIcon.home),
      AppNavigationDestinationItem(
        label: 'Weight',
        icon: AppIcon.weight,
        badgeText: 'New',
      ),
      AppNavigationDestinationItem(label: 'Workouts', icon: AppIcon.workout),
      AppNavigationDestinationItem(label: 'Profile', icon: AppIcon.profile),
    ];

    final pageTitles = [
      'Dashboard Overview',
      'Weight Tracking',
      'Workout Routines',
      'User Profile',
    ];

    return AppNavigationShell(
      title: pageTitles[_selectedIndex],
      destinations: destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      toolbarActions: [
        AppToolbarAction(
          tooltip: 'Add Measurement',
          icon: AppIcon.addMeasurement,
          onPressed: () {},
        ),
        AppToolbarAction(
          tooltip: 'Settings',
          icon: AppIcon.profile,
          onPressed: () {},
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.resolve(context, destinations[_selectedIndex].icon),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'Destination: ${destinations[_selectedIndex].label}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Container width: ${widget.previewWidth.toInt()}px',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
