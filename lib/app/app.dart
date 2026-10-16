import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/app/router/app_router.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/theme/app_theme.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';

import 'package:intl/intl.dart';

class BulkTempoApp extends ConsumerWidget {
  const BulkTempoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerConfig = ref.watch(appRouterProvider);
    final currentLocale = ref.watch(localeProvider);
    Intl.defaultLocale = currentLocale.languageCode;

    return MaterialApp.router(
      title: 'Bulk Tempo',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      highContrastTheme: AppTheme.highContrastLight(),
      highContrastDarkTheme: AppTheme.highContrastDark(),
      themeMode: ThemeMode.system,
      builder: (context, child) => CupertinoTheme(
        data: AppTheme.cupertinoFromMaterial(Theme.of(context)),
        child: child ?? const SizedBox.shrink(),
      ),
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: routerConfig,
    );
  }
}
