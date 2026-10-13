import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Bulk Tempo'**
  String get appTitle;

  /// Navigation label for Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation label for Weights
  ///
  /// In en, this message translates to:
  /// **'Weights'**
  String get navWeights;

  /// Navigation label for Workouts
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// Navigation label for Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Generic save action button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel action button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic delete action button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic edit action button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic confirm action button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic discard action button
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Generic close action button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Generic retry action button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Generic log out button
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Fallback text when user email is absent
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// Header title on the login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// Subtitle on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your workout logs'**
  String get loginSubtitle;

  /// Label for email text field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Hint text for email text field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// Label for password text field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Hint text for password text field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Hint text for registration password text field
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHintRegister;

  /// Tooltip for showing obscured password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// Tooltip for hiding password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// Button to submit login form
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// Button navigating from login to register screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccountButton;

  /// Header title on the register screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// Subtitle on the register screen
  ///
  /// In en, this message translates to:
  /// **'Start tracking your workouts today'**
  String get registerSubtitle;

  /// Button to submit register form
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// Button navigating from register to login screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccountButton;

  /// Title of logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutDialogTitle;

  /// Content of logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutDialogContent;

  /// Confirm button text in logout dialog
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutDialogConfirm;

  /// Greeting on home shell dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bulk Tempo'**
  String get homeWelcomeTitle;

  /// Navigation button on home screen to weights tab
  ///
  /// In en, this message translates to:
  /// **'Go to Weights'**
  String get homeGoToWeights;

  /// Navigation button on home screen to workouts tab
  ///
  /// In en, this message translates to:
  /// **'Go to Workouts'**
  String get homeGoToWorkouts;

  /// Button label for logging out
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutButton;

  /// Heading for profile section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Heading for Hevy card on profile tab
  ///
  /// In en, this message translates to:
  /// **'Hevy Integration'**
  String get hevyIntegrationTitle;

  /// Label for Hevy connection status
  ///
  /// In en, this message translates to:
  /// **'Connection status:'**
  String get connectionStatusLabel;

  /// Status text when Hevy API key is not connected
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get hevyNotConnected;

  /// Button to update configured Hevy key
  ///
  /// In en, this message translates to:
  /// **'Update Key'**
  String get updateKeyButton;

  /// Button to connect Hevy key on profile tab
  ///
  /// In en, this message translates to:
  /// **'Connect Hevy Key'**
  String get connectHevyKeyButton;

  /// Button to disconnect Hevy key
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButton;

  /// Title for language preference card
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Language selector option that follows the device language
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Segmented button label for English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Segmented button label for Polish language
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get languagePolish;

  /// Empty state title on weight history view
  ///
  /// In en, this message translates to:
  /// **'No weight entries yet'**
  String get weightEmptyTitle;

  /// Empty state subtitle on weight history view
  ///
  /// In en, this message translates to:
  /// **'Track your weight progression consistently to see trends over time.'**
  String get weightEmptySubtitle;

  /// Button to add first weight on empty state
  ///
  /// In en, this message translates to:
  /// **'Add First Weight'**
  String get addFirstWeightButton;

  /// Extended FAB label to add a weight entry
  ///
  /// In en, this message translates to:
  /// **'Add Weight'**
  String get addWeightButton;

  /// Title of weight bottom sheet when logging a new entry
  ///
  /// In en, this message translates to:
  /// **'Log Body Weight'**
  String get logWeightTitle;

  /// Title of weight bottom sheet when editing an entry
  ///
  /// In en, this message translates to:
  /// **'Edit Weight Entry'**
  String get editWeightTitle;

  /// Label for weight input field
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightFieldLabel;

  /// Hint text for weight input field
  ///
  /// In en, this message translates to:
  /// **'e.g. 78.50'**
  String get weightFieldHint;

  /// Primary button in weight entry bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Save Weight'**
  String get saveWeightButton;

  /// Confirm button text in weight deletion dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteWeightButton;

  /// Outlined delete button in weight entry bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteWeightEntryButton;

  /// Title of overwrite confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Overwrite Weight Entry?'**
  String get overwriteDialogTitle;

  /// Content of overwrite confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'A weight of {weight} is already recorded for this date. Do you want to replace it?'**
  String overwriteDialogContent(String weight);

  /// Fallback text when existing weight is unavailable in overwrite dialog
  ///
  /// In en, this message translates to:
  /// **'an existing weight'**
  String get overwriteDialogExistingWeightFallback;

  /// Confirm button in overwrite dialog
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get overwriteDialogConfirm;

  /// Title of weight delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Weight Entry?'**
  String get deleteWeightDialogTitle;

  /// Content of weight delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Permanently delete the measurement of {weight} recorded on {date}?'**
  String deleteWeightDialogContent(String weight, String date);

  /// Title of unsaved changes discard dialog
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardDialogTitle;

  /// Content of unsaved changes discard dialog
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them or keep editing?'**
  String get discardDialogContent;

  /// Button to continue editing in discard dialog
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditingButton;

  /// Button to confirm discarding unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// Snackbar message when a weight entry is deleted
  ///
  /// In en, this message translates to:
  /// **'Weight entry deleted successfully'**
  String get weightDeletedSuccess;

  /// Snackbar message when a weight entry is saved
  ///
  /// In en, this message translates to:
  /// **'Weight entry saved successfully'**
  String get weightSavedSuccess;

  /// Chip label showing count of logged days in week
  ///
  /// In en, this message translates to:
  /// **'{count}/7 days'**
  String loggedDaysLabel(int count);

  /// Subtitle showing weekly average weight
  ///
  /// In en, this message translates to:
  /// **'{weight} kg avg'**
  String weightAverageLabel(String weight);

  /// Tooltip for edit button on daily weight item
  ///
  /// In en, this message translates to:
  /// **'Edit weight entry'**
  String get editWeightTooltip;

  /// Message when no weekly data is available for chart
  ///
  /// In en, this message translates to:
  /// **'No weekly data available'**
  String get chartNoData;

  /// Title header above weekly weight chart
  ///
  /// In en, this message translates to:
  /// **'Weekly Weight Trend'**
  String get chartWeeklyTrendTitle;

  /// Helper hint banner when only a single week of weight data exists
  ///
  /// In en, this message translates to:
  /// **'Log weights in at least 2 weeks to see a multi-week trend line'**
  String get chartSingleWeekHint;

  /// Title for unconfigured Hevy state in workouts tab
  ///
  /// In en, this message translates to:
  /// **'Connect Hevy Workouts'**
  String get connectHevyTitle;

  /// Description banner for unconfigured Hevy workouts
  ///
  /// In en, this message translates to:
  /// **'Import your last 12 weeks of workouts directly from Hevy. Generate your Hevy Pro API key at https://hevy.com/settings?developer and enter it below.'**
  String get connectHevySubtitle;

  /// Title in Hevy key modal bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Connect Hevy API Key'**
  String get connectHevyKeyTitle;

  /// Subtitle in Hevy key modal bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Generate your Hevy Pro API key at https://hevy.com/settings?developer and paste the UUID below.'**
  String get connectHevyKeySubtitle;

  /// Label for Hevy API key input field
  ///
  /// In en, this message translates to:
  /// **'Hevy API Key (UUID)'**
  String get hevyKeyInputLabel;

  /// Hint text for Hevy API key UUID format
  ///
  /// In en, this message translates to:
  /// **'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'**
  String get hevyKeyInputHint;

  /// Primary action button to submit Hevy key inline
  ///
  /// In en, this message translates to:
  /// **'Connect Hevy'**
  String get connectHevyButton;

  /// Primary action button in Hevy key modal bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Save & Connect'**
  String get saveAndConnectButton;

  /// Button to update Hevy key from error state
  ///
  /// In en, this message translates to:
  /// **'Update API Key'**
  String get updateApiKeyButton;

  /// Title displayed when user has connected Hevy but has no workouts
  ///
  /// In en, this message translates to:
  /// **'No workouts in the last 12 weeks'**
  String get workoutEmptyTitle;

  /// Subtitle displayed when user has connected Hevy but has no workouts
  ///
  /// In en, this message translates to:
  /// **'Log a workout in Hevy and refresh to see your weekly training volume.'**
  String get workoutEmptySubtitle;

  /// Button to refresh workouts on empty state
  ///
  /// In en, this message translates to:
  /// **'Refresh Workouts'**
  String get refreshWorkoutsButton;

  /// Text button to refresh workouts list
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// Header title displaying total workout count over last 12 weeks
  ///
  /// In en, this message translates to:
  /// **'Last 12 Weeks ({count} {count, plural, =1{workout} other{workouts}})'**
  String last12WeeksWorkouts(int count);

  /// Chip label showing count of workouts in a weekly card
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{workout} other{workouts}}'**
  String workoutCountChip(int count);

  /// Summary line displaying working set count and volume
  ///
  /// In en, this message translates to:
  /// **'{sets} working sets • {volume} kg volume'**
  String workoutDetailSummary(int sets, String volume);

  /// Pluralized label for exercise count in workout card item
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{exercise} other{exercises}}'**
  String exerciseCountLabel(int count);

  /// Pluralized label for working sets in workout card item
  ///
  /// In en, this message translates to:
  /// **'{count} working {count, plural, =1{set} other{sets}}'**
  String workingSetsCountLabel(int count);

  /// Empty state text in workout detail bottom sheet
  ///
  /// In en, this message translates to:
  /// **'No exercises recorded for this workout.'**
  String get workoutNoExercises;

  /// Chip label showing the best working set performance
  ///
  /// In en, this message translates to:
  /// **'Best: {performance}'**
  String bestSetLabel(String performance);

  /// Badge text for warmup set
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get setTypeWarmup;

  /// Badge text for set to failure
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get setTypeFailure;

  /// Badge text for dropset
  ///
  /// In en, this message translates to:
  /// **'Dropset'**
  String get setTypeDropset;

  /// Pluralized repetitions count
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{rep} other{reps}}'**
  String repsCount(int count);

  /// Duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesDuration(int minutes);

  /// Title of weekly gain target card
  ///
  /// In en, this message translates to:
  /// **'Weekly Gain Target'**
  String get gainTargetTitle;

  /// Tooltip for refresh button on weekly gain target card
  ///
  /// In en, this message translates to:
  /// **'Refresh target'**
  String get gainTargetRefreshTooltip;

  /// Label preceding current gain target value
  ///
  /// In en, this message translates to:
  /// **'Current target: '**
  String get gainTargetCurrentLabel;

  /// Text displayed when no gain target is set
  ///
  /// In en, this message translates to:
  /// **'No target set'**
  String get gainTargetNoTargetSet;

  /// Label for minimum weekly gain input field
  ///
  /// In en, this message translates to:
  /// **'Minimum weekly gain'**
  String get minWeeklyGainLabel;

  /// Label for maximum weekly gain input field
  ///
  /// In en, this message translates to:
  /// **'Maximum weekly gain'**
  String get maxWeeklyGainLabel;

  /// Suffix unit for weekly gain rate
  ///
  /// In en, this message translates to:
  /// **'kg/week'**
  String get kgPerWeekUnit;

  /// Button to save weekly gain target
  ///
  /// In en, this message translates to:
  /// **'Save Target'**
  String get saveTargetButton;

  /// Indicator text when gain target save is submitting
  ///
  /// In en, this message translates to:
  /// **'Waiting for server confirmation'**
  String get gainTargetWaitingConfirmation;

  /// Snackbar message when gain target is saved
  ///
  /// In en, this message translates to:
  /// **'Weekly gain target saved successfully'**
  String get gainTargetSavedSuccess;

  /// Validation error when weight input is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a weight'**
  String get weightErrorEmpty;

  /// Validation error when weight input has invalid format
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight with up to 2 decimal places'**
  String get weightErrorInvalidFormat;

  /// Validation error when weight is outside allowed bounds
  ///
  /// In en, this message translates to:
  /// **'Weight must be between {min} and {max} kg'**
  String weightErrorOutOfBounds(String min, String max);

  /// Validation error when weight entry date is in the future
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the future'**
  String get weightErrorFutureDate;

  /// Validation error when weight entry date exceeds maximum lookback
  ///
  /// In en, this message translates to:
  /// **'Date cannot be more than {days} days in the past'**
  String weightErrorLookbackExceeded(int days);

  /// Validation error when Hevy API key is empty
  ///
  /// In en, this message translates to:
  /// **'Hevy API key is required'**
  String get hevyKeyErrorEmpty;

  /// Validation error when Hevy API key is not a valid UUID
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Hevy API key (UUID format)'**
  String get hevyKeyErrorInvalidUuid;

  /// Abbreviated Monday
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// Abbreviated Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// Abbreviated Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// Abbreviated Thursday
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// Abbreviated Friday
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// Abbreviated Saturday
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// Abbreviated Sunday
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// Abbreviated January
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// Abbreviated February
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// Abbreviated March
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// Abbreviated April
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// Abbreviated May
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// Abbreviated June
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// Abbreviated July
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// Abbreviated August
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// Abbreviated September
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// Abbreviated October
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// Abbreviated November
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// Abbreviated December
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
