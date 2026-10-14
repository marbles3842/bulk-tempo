import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/constants/locale_constants.dart';
import 'package:bulk_tempo/core/localization/locale_notifier.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';

export 'package:bulk_tempo/core/constants/locale_constants.dart';

/// Provider exposing the active application [Locale].
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Convenience extension on [BuildContext] to access [AppLocalizations].
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      lookupAppLocalizations(LocaleConstants.englishLocale);
}
