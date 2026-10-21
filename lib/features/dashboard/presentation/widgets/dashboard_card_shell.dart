import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';

/// Reusable card shell for dashboard metric and chart cards.
///
/// Provides a consistent [AppCard] header with title, optional subtitle,
/// optional leading icon, optional outdated badge, and handles loading, error,
/// empty, and unconfigured presentation states cleanly.
class DashboardCardShell extends StatelessWidget {
  final Key? cardKey;
  final String title;
  final String? subtitle;
  final Key? subtitleKey;
  final AppIcon? leadingIcon;
  final bool isOutdated;
  final Key? outdatedBadgeKey;
  final DashboardCardStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Key? retryButtonKey;
  final String? emptyMessage;
  final Key? emptyMessageKey;
  final String? unconfiguredMessage;
  final Key? unconfiguredMessageKey;
  final Widget child;
  final double contentHeight;

  const DashboardCardShell({
    super.key,
    this.cardKey,
    required this.title,
    this.subtitle,
    this.subtitleKey,
    this.leadingIcon,
    this.isOutdated = false,
    this.outdatedBadgeKey,
    required this.status,
    this.errorMessage,
    this.onRetry,
    this.retryButtonKey,
    this.emptyMessage,
    this.emptyMessageKey,
    this.unconfiguredMessage,
    this.unconfiguredMessageKey,
    required this.child,
    this.contentHeight = AppChartTheme.defaultChartHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      cardKey: cardKey,
      title: title,
      subtitle: subtitle,
      subtitleKey: subtitleKey,
      leadingIcon: leadingIcon,
      headerTrailing: isOutdated
          ? AppStatusBadge(
              badgeKey: outdatedBadgeKey,
              label: context.l10n.dashboardOutdatedBadge,
              tone: AppFeedbackTone.warning,
              icon: AppIcon.warning,
            )
          : null,
      variant: AppCardVariant.grouped,
      margin: EdgeInsets.zero,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final capabilities = PresentationCapabilities.resolve(context);

    switch (status) {
      case DashboardCardStatus.loading:
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: contentHeight),
          child: Center(
            child: capabilities.platformMode != AdaptivePlatformMode.material
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          ),
        );

      case DashboardCardStatus.error:
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: contentHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.resolve(context, AppIcon.error),
                  color: theme.colorScheme.error,
                  size: AppIcons.normalSize,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  errorMessage ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.relatedGap),
                  AppButton(
                    key: retryButtonKey,
                    label: context.l10n.retry,
                    variant: AppButtonVariant.tonal,
                    icon: AppIcon.retry,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        );

      case DashboardCardStatus.empty:
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: contentHeight),
          child: Center(
            child: Text(
              emptyMessage ?? '',
              key: emptyMessageKey,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );

      case DashboardCardStatus.unconfigured:
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: contentHeight),
          child: Center(
            child: Text(
              unconfiguredMessage ?? '',
              key: unconfiguredMessageKey,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );

      case DashboardCardStatus.loaded:
        return child;
    }
  }
}
