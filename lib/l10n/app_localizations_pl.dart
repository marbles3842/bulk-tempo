// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Bulk Tempo';

  @override
  String get navHome => 'Start';

  @override
  String get navWeights => 'Waga';

  @override
  String get navWorkouts => 'Treningi';

  @override
  String get navProfile => 'Profil';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get edit => 'Edytuj';

  @override
  String get confirm => 'Zatwierdź';

  @override
  String get discard => 'Odrzuć';

  @override
  String get close => 'Zamknij';

  @override
  String get logOut => 'Wyloguj się';

  @override
  String get weightErrorEmpty => 'Wprowadź wagę';

  @override
  String get weightErrorInvalidFormat =>
      'Wprowadź poprawną wagę z maksymalnie 2 miejscami po przecinku';

  @override
  String weightErrorOutOfBounds(String min, String max) {
    return 'Waga musi mieścić się w przedziale od $min do $max kg';
  }

  @override
  String get weightErrorFutureDate => 'Data nie może być z przyszłości';

  @override
  String weightErrorLookbackExceeded(int days) {
    return 'Data nie może być starsza niż $days dni';
  }

  @override
  String get hevyKeyErrorEmpty => 'Klucz API Hevy jest wymagany';

  @override
  String get hevyKeyErrorInvalidUuid =>
      'Wprowadź poprawny klucz API Hevy (format UUID)';

  @override
  String get weekdayMon => 'pon.';

  @override
  String get weekdayTue => 'wt.';

  @override
  String get weekdayWed => 'śr.';

  @override
  String get weekdayThu => 'czw.';

  @override
  String get weekdayFri => 'pt.';

  @override
  String get weekdaySat => 'sob.';

  @override
  String get weekdaySun => 'niedz.';

  @override
  String get monthJan => 'sty';

  @override
  String get monthFeb => 'lut';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'kwi';

  @override
  String get monthMay => 'maj';

  @override
  String get monthJun => 'cze';

  @override
  String get monthJul => 'lip';

  @override
  String get monthAug => 'sie';

  @override
  String get monthSep => 'wrz';

  @override
  String get monthOct => 'paź';

  @override
  String get monthNov => 'lis';

  @override
  String get monthDec => 'gru';
}
