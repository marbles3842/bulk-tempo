import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';

/// Reusable card shell for dashboard metric and chart cards.
///
/// Provides a consistent [Card] header with title, optional subtitle, optional
/// outdated badge, and handles loading, error, empty, and unconfigured presentation
/// states cleanly.
class DashboardCardShell extends StatelessWidget {
  final Key? cardKey;
  final String title;
  final String? subtitle;
  final Key? subtitleKey;
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
    this.contentHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: cardKey,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          key: subtitleKey,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOutdated) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: outdatedBadgeKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.dashboardOutdatedBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    switch (status) {
      case DashboardCardStatus.loading:
        return SizedBox(
          height: contentHeight,
          child: const Center(child: CircularProgressIndicator()),
        );

      case DashboardCardStatus.error:
        return SizedBox(
          height: contentHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  errorMessage ?? 'Failed to load data',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    key: retryButtonKey,
                    onPressed: onRetry,
                    child: Text(context.l10n.retry),
                  ),
                ],
              ],
            ),
          ),
        );

      case DashboardCardStatus.empty:
        return SizedBox(
          height: contentHeight,
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
        return SizedBox(
          height: contentHeight,
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
