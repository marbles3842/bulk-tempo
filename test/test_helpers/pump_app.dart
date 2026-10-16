import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_theme.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';

extension PumpAppExtension on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
    ThemeData? theme,
    PresentationCapabilities? capabilities,
  }) async {
    final effectiveOverrides = <Override>[
      ...overrides,
      if (capabilities != null)
        presentationCapabilitiesOverrideProvider.overrideWithValue(
          capabilities,
        ),
    ];

    await pumpWidget(
      ProviderScope(
        overrides: effectiveOverrides,
        child: MaterialApp(
          locale: locale,
          theme: theme ?? AppTheme.light(),
          darkTheme: AppTheme.dark(),
          highContrastTheme: AppTheme.highContrastLight(),
          highContrastDarkTheme: AppTheme.highContrastDark(),
          themeMode: themeMode,
          builder: (context, child) => CupertinoTheme(
            data: AppTheme.cupertinoFromMaterial(Theme.of(context)),
            child: child ?? const SizedBox.shrink(),
          ),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: widget,
        ),
      ),
    );
  }
}
