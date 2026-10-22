import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = PresentationCapabilities.resolve(context);
    final isMaterial =
        capabilities.platformMode == AdaptivePlatformMode.material;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.resolve(context, AppIcon.workout, selected: true),
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              context.l10n.appTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            if (isMaterial)
              const CircularProgressIndicator()
            else
              const CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }
}
