import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';

/// Modal bottom sheet container providing:
/// - Opaque sheet surface (`colorScheme.surfaceContainerHigh`).
/// - Standard top corner radii (`AppShape.sheetTopRadius`, 24px) and insets (24px).
/// - Dynamic `MediaQuery.viewInsetsOf(context).bottom` keyboard clearance.
/// - Title and close button header with optional subtitle and summary text.
/// - Optional [DraggableScrollableSheet] mode.
/// - Caller-controlled dismissal guards ([canPop] + [onDismissRequested])
///   intercepting system back, overscroll at top, and swipe-down gestures.
class AppSheetFrame extends ConsumerStatefulWidget {
  /// Default initial fractional height for draggable sheets.
  static const double defaultInitialChildSize = 0.75;

  /// Default minimum fractional height for draggable sheets.
  static const double defaultMinChildSize = 0.45;

  /// Default maximum fractional height for draggable sheets.
  static const double defaultMaxChildSize = 0.92;

  /// Single-frame upward overscroll / scroll-delta threshold (in logical pixels)
  /// at the top edge of the sheet's vertical scroll view that requests dismissal.
  static const double dismissOverscrollThreshold = -20.0;

  /// Cumulative downward vertical drag distance (in logical pixels) that
  /// requests sheet dismissal on drag end.
  static const double dismissDragDistanceThreshold = 100.0;

  /// Downward fling velocity (in logical pixels per second) that requests
  /// sheet dismissal on drag end.
  static const double dismissFlingVelocityThreshold = 250.0;

  const AppSheetFrame({
    super.key,
    this.sheetKey,
    required this.title,
    this.subtitle,
    this.summaryText,
    this.closeButtonKey,
    this.closeTooltip,
    this.canPop = true,
    this.isBusy = false,
    this.onDismissRequested,
    this.isDraggable = false,
    this.initialChildSize = defaultInitialChildSize,
    this.minChildSize = defaultMinChildSize,
    this.maxChildSize = defaultMaxChildSize,
    this.maxWidth = AppSpacing.formMaxWidth,
    this.child,
    this.scrollableBuilder,
  }) : assert(
         child != null || scrollableBuilder != null,
         'Either child or scrollableBuilder must be provided',
       );

  /// Optional [Key] assigned to the sheet's surface container.
  final Key? sheetKey;

  /// Main header title text.
  final String title;

  /// Optional secondary header text below the title.
  final String? subtitle;

  /// Optional tertiary summary text below the subtitle.
  final String? summaryText;

  /// Optional [Key] assigned to the header close button.
  final Key? closeButtonKey;

  /// Tooltip for the close button.
  final String? closeTooltip;

  /// When false, dismissal attempts via system back, close button, overscroll,
  /// or swipe-down trigger [onDismissRequested] instead of popping.
  final bool canPop;

  /// When true, ongoing work disables close actions and prevents dismissal.
  final bool isBusy;

  /// Callback executed when dismissal is requested while [canPop] is false
  /// (or when caller wants custom handling before dismiss).
  final FutureOr<void> Function()? onDismissRequested;

  /// When true, renders inside a [DraggableScrollableSheet].
  final bool isDraggable;

  /// Initial fractional height when [isDraggable] is true (default 0.75).
  final double initialChildSize;

  /// Minimum fractional height when [isDraggable] is true (default 0.45).
  final double minChildSize;

  /// Maximum fractional height when [isDraggable] is true (default 0.92).
  final double maxChildSize;

  /// Maximum sheet width constraint (default [AppSpacing.formMaxWidth]).
  final double maxWidth;

  /// Sheet body widget when [scrollableBuilder] is not used.
  final Widget? child;

  /// Optional scrollable builder receiving a [ScrollController] (e.g. for draggable sheets).
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
  )?
  scrollableBuilder;

  /// Static helper presenting [builder] inside an [AppSheetFrame]-ready modal bottom sheet.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool enableDrag = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
      builder: builder,
    );
  }

  @override
  ConsumerState<AppSheetFrame> createState() => _AppSheetFrameState();
}

class _AppSheetFrameState extends ConsumerState<AppSheetFrame> {
  late final ScrollController _scrollController = ScrollController();
  double _dragDistance = 0.0;
  bool _dismissInFlight = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleDismissRequest() async {
    if (widget.isBusy || _dismissInFlight) return;
    _dismissInFlight = true;
    try {
      if (!widget.canPop || widget.onDismissRequested != null) {
        await widget.onDismissRequested?.call();
      } else if (mounted) {
        await Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) {
        _dismissInFlight = false;
      }
    }
  }

  String _resolveCloseTooltip(BuildContext context) {
    if (widget.closeTooltip != null) return widget.closeTooltip!;
    try {
      return MaterialLocalizations.of(context).closeButtonTooltip;
    } catch (_) {
      return 'Close';
    }
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppSpacing.space1),
                Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (widget.summaryText != null) ...[
                const SizedBox(height: AppSpacing.space1),
                Text(
                  widget.summaryText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          key: widget.closeButtonKey,
          icon: Icon(AppIcons.resolve(context, AppIcon.close)),
          tooltip: _resolveCloseTooltip(context),
          onPressed: widget.isBusy ? null : _handleDismissRequest,
        ),
      ],
    );
  }

  Widget _buildSheetContainer({
    required BuildContext context,
    required ThemeData theme,
    required Widget child,
  }) {
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Container(
          key: widget.sheetKey,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: AppShape.sheetTopRadius,
          ),
          padding: EdgeInsets.only(
            top: AppSpacing.sheetInset,
            left: AppSpacing.sheetInset,
            right: AppSpacing.sheetInset,
            bottom: viewInsetsBottom + AppSpacing.sheetInset,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sheetContent;
    if (widget.isDraggable) {
      sheetContent = DraggableScrollableSheet(
        initialChildSize: widget.initialChildSize,
        minChildSize: widget.minChildSize,
        maxChildSize: widget.maxChildSize,
        expand: false,
        builder: (context, scrollController) {
          return _buildSheetContainer(
            context: context,
            theme: theme,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: AppSpacing.space4),
                Expanded(
                  child: widget.scrollableBuilder != null
                      ? widget.scrollableBuilder!(context, scrollController)
                      : SingleChildScrollView(
                          controller: scrollController,
                          child: widget.child!,
                        ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final Widget bodyContent;
      if (widget.scrollableBuilder != null) {
        bodyContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: AppSpacing.space4),
            if (widget.child != null) widget.child!,
            Flexible(
              child: widget.scrollableBuilder!(context, _scrollController),
            ),
          ],
        );
      } else {
        bodyContent = SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: AppSpacing.space4),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      }

      sheetContent = _buildSheetContainer(
        context: context,
        theme: theme,
        child: bodyContent,
      );
    }

    return PopScope(
      canPop: widget.canPop && !widget.isBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleDismissRequest();
      },
      child: Material(
        color: Colors.transparent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0 ||
                notification.metrics.axis != Axis.vertical) {
              return false;
            }
            if (notification is OverscrollNotification &&
                notification.overscroll <
                    AppSheetFrame.dismissOverscrollThreshold) {
              _handleDismissRequest();
              return true;
            }
            if (notification is ScrollUpdateNotification &&
                notification.metrics.pixels <= 0 &&
                (notification.scrollDelta ?? 0) <
                    AppSheetFrame.dismissOverscrollThreshold) {
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
              if (_dragDistance > AppSheetFrame.dismissDragDistanceThreshold ||
                  (details.primaryVelocity ?? 0) >
                      AppSheetFrame.dismissFlingVelocityThreshold) {
                _handleDismissRequest();
              }
              _dragDistance = 0.0;
            },
            onVerticalDragCancel: () {
              _dragDistance = 0.0;
            },
            child: sheetContent,
          ),
        ),
      ),
    );
  }
}
