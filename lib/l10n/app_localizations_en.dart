// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bulk Tempo';

  @override
  String get navHome => 'Home';

  @override
  String get navWeights => 'Weights';

  @override
  String get navWorkouts => 'Workouts';

  @override
  String get navProfile => 'Profile';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get discard => 'Discard';

  @override
  String get close => 'Close';

  @override
  String get logOut => 'Log Out';

  @override
  String get weightErrorEmpty => 'Please enter a weight';

  @override
  String get weightErrorInvalidFormat =>
      'Enter a valid weight with up to 2 decimal places';

  @override
  String weightErrorOutOfBounds(String min, String max) {
    return 'Weight must be between $min and $max kg';
  }

  @override
  String get weightErrorFutureDate => 'Date cannot be in the future';

  @override
  String weightErrorLookbackExceeded(int days) {
    return 'Date cannot be more than $days days in the past';
  }

  @override
  String get hevyKeyErrorEmpty => 'Hevy API key is required';

  @override
  String get hevyKeyErrorInvalidUuid =>
      'Enter a valid Hevy API key (UUID format)';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';
}
