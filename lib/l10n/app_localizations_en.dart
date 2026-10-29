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
  String get retry => 'Retry';

  @override
  String get logOut => 'Log Out';

  @override
  String get noEmail => 'No email';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to access your workout logs';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordHintRegister => 'At least 6 characters';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get loginButton => 'Log In';

  @override
  String get dontHaveAccountButton => 'Don\'t have an account? Sign up';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Start tracking your workouts today';

  @override
  String get registerButton => 'Create Account';

  @override
  String get alreadyHaveAccountButton => 'Already have an account? Log in';

  @override
  String get logoutDialogTitle => 'Log Out';

  @override
  String get logoutDialogContent => 'Are you sure you want to log out?';

  @override
  String get logoutDialogConfirm => 'Log Out';

  @override
  String get homeWelcomeTitle => 'Welcome to Bulk Tempo';

  @override
  String get homeGoToWeights => 'Go to Weights';

  @override
  String get homeGoToWorkouts => 'Go to Workouts';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get profileTitle => 'Profile';

  @override
  String get hevyIntegrationTitle => 'Hevy Integration';

  @override
  String get connectionStatusLabel => 'Connection status:';

  @override
  String get hevyNotConnected => 'Not connected';

  @override
  String get updateKeyButton => 'Update Key';

  @override
  String get connectHevyKeyButton => 'Connect Hevy Key';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polski';

  @override
  String get weightEmptyTitle => 'No weight entries yet';

  @override
  String get weightEmptySubtitle =>
      'Track your weight progression consistently to see trends over time.';

  @override
  String get addFirstWeightButton => 'Add First Weight';

  @override
  String get addWeightButton => 'Add Weight';

  @override
  String get logWeightTitle => 'Log Body Weight';

  @override
  String get editWeightTitle => 'Edit Weight Entry';

  @override
  String get weightFieldLabel => 'Weight (kg)';

  @override
  String get weightFieldHint => 'e.g. 78.50';

  @override
  String get saveWeightButton => 'Save Weight';

  @override
  String get deleteWeightButton => 'Delete';

  @override
  String get deleteWeightEntryButton => 'Delete Entry';

  @override
  String get overwriteDialogTitle => 'Overwrite Weight Entry?';

  @override
  String overwriteDialogContent(String weight) {
    return 'A weight of $weight is already recorded for this date. Do you want to replace it?';
  }

  @override
  String get overwriteDialogExistingWeightFallback => 'an existing weight';

  @override
  String get overwriteDialogConfirm => 'Replace';

  @override
  String get deleteWeightDialogTitle => 'Delete Weight Entry?';

  @override
  String deleteWeightDialogContent(String weight, String date) {
    return 'Permanently delete the measurement of $weight recorded on $date?';
  }

  @override
  String get discardDialogTitle => 'Discard Changes?';

  @override
  String get discardDialogContent =>
      'You have unsaved changes. Do you want to discard them or keep editing?';

  @override
  String get keepEditingButton => 'Keep Editing';

  @override
  String get discardButton => 'Discard';

  @override
  String get weightDeletedSuccess => 'Weight entry deleted successfully';

  @override
  String get weightSavedSuccess => 'Weight entry saved successfully';

  @override
  String loggedDaysLabel(int count) {
    return '$count/7 days';
  }

  @override
  String weightAverageLabel(String weight) {
    return '$weight kg avg';
  }

  @override
  String get editWeightTooltip => 'Edit weight entry';

  @override
  String get chartNoData => 'No weekly data available';

  @override
  String get chartWeeklyTrendTitle => 'Weekly Weight Trend';

  @override
  String get chartSingleWeekHint =>
      'Log weights in at least 2 weeks to see a multi-week trend line';

  @override
  String get connectHevyTitle => 'Connect Hevy Workouts';

  @override
  String get connectHevySubtitle =>
      'Import your last 12 weeks of workouts directly from Hevy. Generate your Hevy Pro API key at https://hevy.com/settings?developer and enter it below.';

  @override
  String get connectHevyKeyTitle => 'Connect Hevy API Key';

  @override
  String get connectHevyKeySubtitle =>
      'Generate your Hevy Pro API key at https://hevy.com/settings?developer and paste the UUID below.';

  @override
  String get hevyKeyInputLabel => 'Hevy API Key (UUID)';

  @override
  String get hevyKeyInputHint => 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

  @override
  String get connectHevyButton => 'Connect Hevy';

  @override
  String get saveAndConnectButton => 'Save & Connect';

  @override
  String get updateApiKeyButton => 'Update API Key';

  @override
  String get workoutEmptyTitle => 'No workouts in the last 12 weeks';

  @override
  String get workoutEmptySubtitle =>
      'Log a workout in Hevy and refresh to see your weekly training volume.';

  @override
  String get refreshWorkoutsButton => 'Refresh Workouts';

  @override
  String get refreshButton => 'Refresh';

  @override
  String last12WeeksWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'workouts',
      one: 'workout',
    );
    return 'Last 12 Weeks ($count $_temp0)';
  }

  @override
  String workoutCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'workouts',
      one: 'workout',
    );
    return '$count $_temp0';
  }

  @override
  String workoutDetailSummary(int sets, String volume) {
    return '$sets working sets • $volume kg volume';
  }

  @override
  String exerciseCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'exercises',
      one: 'exercise',
    );
    return '$count $_temp0';
  }

  @override
  String workingSetsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sets',
      one: 'set',
    );
    return '$count working $_temp0';
  }

  @override
  String get workoutNoExercises => 'No exercises recorded for this workout.';

  @override
  String bestSetLabel(String performance) {
    return 'Best: $performance';
  }

  @override
  String get setTypeWarmup => 'Warmup';

  @override
  String get setTypeFailure => 'Failure';

  @override
  String get setTypeDropset => 'Dropset';

  @override
  String repsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reps',
      one: 'rep',
    );
    return '$count $_temp0';
  }

  @override
  String minutesDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String get gainTargetTitle => 'Weekly Gain Target';

  @override
  String get gainTargetRefreshTooltip => 'Refresh target';

  @override
  String get gainTargetCurrentLabel => 'Current target: ';

  @override
  String get gainTargetNoTargetSet => 'No target set';

  @override
  String get minWeeklyGainLabel => 'Minimum weekly gain';

  @override
  String get maxWeeklyGainLabel => 'Maximum weekly gain';

  @override
  String get kgPerWeekUnit => 'kg/week';

  @override
  String get saveTargetButton => 'Save Target';

  @override
  String get gainTargetWaitingConfirmation => 'Waiting for server confirmation';

  @override
  String get gainTargetSavedSuccess => 'Weekly gain target saved successfully';

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

  @override
  String get dashboardOutdatedBadge => 'Outdated · last refresh failed';

  @override
  String get dashboardKpiPaceTitle => 'Current Pace';

  @override
  String get dashboardKpiPaceSubtitleEmpty => 'Log 2+ weeks';

  @override
  String get dashboardKpiAverageTitle => 'Latest Average';

  @override
  String dashboardKpiAverageSubtitleIncomplete(int loggedDays) {
    return 'This week · $loggedDays/7 days logged';
  }

  @override
  String get dashboardKpiAverageSubtitleComplete =>
      'This week · 7/7 days logged';

  @override
  String get dashboardKpiTotalGainTitle => 'Total Gain';

  @override
  String get dashboardKpiWorkoutsTitle => 'Workouts This Week';

  @override
  String get dashboardKpiWorkoutsThisWeek => 'This week';

  @override
  String get dashboardKpiWorkoutsNotConnected => 'Not connected';

  @override
  String get dashboardKpiWorkoutsSyncError => 'Sync error';

  @override
  String get dashboardWeightTrendTitle => 'Weekly Weight Trend';

  @override
  String get dashboardWeightEmpty =>
      'No weights logged yet — add one on the Weights tab';

  @override
  String get dashboardPaceTitle => 'Weekly Pace';

  @override
  String get dashboardPaceEmpty =>
      'No weights logged yet — add one on the Weights tab';

  @override
  String get dashboardPaceNeedTwoWeeks =>
      'Log weights in at least 2 weeks to see weekly pace';

  @override
  String dashboardPaceTargetSubtitle(String target) {
    return 'Target: $target';
  }

  @override
  String get dashboardWorkoutsTitle => 'Workouts per Week';

  @override
  String get dashboardWorkoutsUnconfigured =>
      'Hevy not connected — connect in Profile';

  @override
  String dashboardWorkoutsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String dashboardPaceMetric(String sign, String value, String unit) {
    return '$sign$value $unit';
  }

  @override
  String dashboardWeightMetric(String value) {
    return '$value kg';
  }

  @override
  String dashboardGainMetric(String sign, String value) {
    return '$sign$value kg';
  }

  @override
  String get dashboardAssessmentCardTitle => 'AI Pace Assessment';

  @override
  String get paceStatusOnTarget => 'On target';

  @override
  String get paceStatusTooFast => 'Too fast';

  @override
  String get paceStatusTooSlow => 'Too slow';

  @override
  String get paceStatusStagnant => 'Stagnation';

  @override
  String get paceAssessmentMissingTarget =>
      'Set your weekly gain target in Profile to unlock AI pace assessment.';

  @override
  String get paceAssessmentMissingHevy =>
      'Connect your Hevy API key in Profile to include workout context in your pace assessment.';

  @override
  String get paceAssessmentNoWorkouts =>
      'Log or import at least one workout in the last 12 weeks to assess your pace in training context.';

  @override
  String paceAssessmentInsufficientWeights(int priorWeeks) {
    return 'Log weight entries in the current (or previous) week and at least 2 earlier weeks ($priorWeeks/2 prior weeks logged) to unlock pace assessment.';
  }

  @override
  String paceAssessmentPartialWeekBadge(int loggedDays) {
    return 'Partial week ($loggedDays/7 days)';
  }

  @override
  String get paceAssessmentViewReportButton => 'View Full AI Report';

  @override
  String get paceAssessmentRefreshTooltip => 'Refresh AI assessment';

  @override
  String get paceReportTitle => 'AI Pace Assessment Report';

  @override
  String get paceReportWeightTrendSection => 'Weight Trend vs. Target';

  @override
  String get paceReportWorkoutContextSection => 'Workout & Strength Context';

  @override
  String get paceReportTakeawaysSection => 'Actionable Takeaways';

  @override
  String paceReportBaselineLabel(String status) {
    return 'Baseline pace status: $status';
  }
}
