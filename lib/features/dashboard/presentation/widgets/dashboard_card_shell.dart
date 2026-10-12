import 'package:flutter/material.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';

/// Reusable Card layout for dashboard metric cards, handling title, subtitle,
/// outdated status badge, loading indicator, error with retry, and empty guidance.
class DashboardCardShell extends StatelessWidget {
  final Key? cardKey;
  final String title;
  final Widget? subtitle;
  final DashboardCardStatus status;
  final bool isOutdated;
  final Key? outdatedBadgeKey;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Key? retryButtonKey;
  final Widget? emptyContent;
  final Widget child;

  const DashboardCardShell({
    super.key,
    this.cardKey,
    required this.title,
    this.subtitle,
    required this.status,
    this.isOutdated = false,
    this.outdatedBadgeKey,
    this.errorMessage,
    this.onRetry,
    this.retryButtonKey,
    this.emptyContent,
    required this.child,
  });

  Widget _buildOutdatedBadge(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: outdatedBadgeKey,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Outdated · last refresh failed',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    switch (status) {
      case DashboardCardStatus.loading:
        body = const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      case DashboardCardStatus.error:
        body = SizedBox(
          height: 180,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    errorMessage ?? 'Failed to load data',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    key: retryButtonKey,
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      case DashboardCardStatus.empty:
      case DashboardCardStatus.unconfigured:
        body = SizedBox(
          height: 140,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: emptyContent ?? const SizedBox.shrink(),
            ),
          ),
        );
      case DashboardCardStatus.loaded:
        body = child;
    }

    return Card(
      key: cardKey,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                if (isOutdated) _buildOutdatedBadge(context),
              ],
            ),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }
}
