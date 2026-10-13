import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/app/router/app_router.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';

class BulkTempoApp extends ConsumerWidget {
  const BulkTempoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerConfig = ref.watch(appRouterProvider);
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Bulk Tempo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
