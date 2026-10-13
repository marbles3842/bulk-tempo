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
  String get retry => 'Ponów';

  @override
  String get logOut => 'Wyloguj się';

  @override
  String get noEmail => 'Brak adresu e-mail';

  @override
  String get loginTitle => 'Witaj ponownie';

  @override
  String get loginSubtitle =>
      'Zaloguj się, aby uzyskać dostęp do swoich treningów';

  @override
  String get emailLabel => 'Adres e-mail';

  @override
  String get emailHint => 'Wprowadź swój e-mail';

  @override
  String get passwordLabel => 'Hasło';

  @override
  String get passwordHint => 'Wprowadź swoje hasło';

  @override
  String get passwordHintRegister => 'Minimum 6 znaków';

  @override
  String get showPasswordTooltip => 'Pokaż hasło';

  @override
  String get hidePasswordTooltip => 'Ukryj hasło';

  @override
  String get loginButton => 'Zaloguj się';

  @override
  String get dontHaveAccountButton => 'Nie masz konta? Zarejestruj się';

  @override
  String get registerTitle => 'Utwórz konto';

  @override
  String get registerSubtitle => 'Zacznij śledzić swoje treningi już dziś';

  @override
  String get registerButton => 'Utwórz konto';

  @override
  String get alreadyHaveAccountButton => 'Masz już konto? Zaloguj się';

  @override
  String get logoutDialogTitle => 'Wyloguj się';

  @override
  String get logoutDialogContent => 'Czy na pewno chcesz się wylogować?';

  @override
  String get logoutDialogConfirm => 'Wyloguj się';

  @override
  String get homeWelcomeTitle => 'Witaj w Bulk Tempo';

  @override
  String get homeGoToWeights => 'Przejdź do wagi';

  @override
  String get homeGoToWorkouts => 'Przejdź do treningów';

  @override
  String get logoutButton => 'Wyloguj się';

  @override
  String get profileTitle => 'Profil';

  @override
  String get hevyIntegrationTitle => 'Integracja z Hevy';

  @override
  String get connectionStatusLabel => 'Status połączenia:';

  @override
  String get hevyNotConnected => 'Nie połączono';

  @override
  String get updateKeyButton => 'Zaktualizuj klucz';

  @override
  String get connectHevyKeyButton => 'Połącz klucz Hevy';

  @override
  String get disconnectButton => 'Rozłącz';

  @override
  String get languageLabel => 'Język';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polski';

  @override
  String get weightEmptyTitle => 'Brak wpisów wagi';

  @override
  String get weightEmptySubtitle =>
      'Regularnie zapisuj wagę, aby obserwować trendy w czasie.';

  @override
  String get addFirstWeightButton => 'Dodaj pierwszą wagę';

  @override
  String get addWeightButton => 'Dodaj wagę';

  @override
  String get logWeightTitle => 'Zapisz wagę ciała';

  @override
  String get editWeightTitle => 'Edytuj wpis wagi';

  @override
  String get weightFieldLabel => 'Waga (kg)';

  @override
  String get weightFieldHint => 'np. 78.50';

  @override
  String get saveWeightButton => 'Zapisz wagę';

  @override
  String get deleteWeightButton => 'Usuń';

  @override
  String get deleteWeightEntryButton => 'Usuń wpis';

  @override
  String get overwriteDialogTitle => 'Zastąpić wpis wagi?';

  @override
  String overwriteDialogContent(String weight) {
    return 'Wpis o wadze $weight już istnieje dla tej daty. Czy chcesz go zastąpić?';
  }

  @override
  String get overwriteDialogExistingWeightFallback => 'istniejącą wagą';

  @override
  String get overwriteDialogConfirm => 'Zastąp';

  @override
  String get deleteWeightDialogTitle => 'Usunąć wpis wagi?';

  @override
  String deleteWeightDialogContent(String weight, String date) {
    return 'Czy trwale usunąć pomiar $weight z dnia $date?';
  }

  @override
  String get discardDialogTitle => 'Odrzucić zmiany?';

  @override
  String get discardDialogContent =>
      'Masz niezapisane zmiany. Czy chcesz je odrzucić, czy kontynuować edycję?';

  @override
  String get keepEditingButton => 'Kontynuuj edycję';

  @override
  String get discardButton => 'Odrzuć';

  @override
  String get weightDeletedSuccess => 'Wpis wagi został pomyślnie usunięty';

  @override
  String get weightSavedSuccess => 'Wpis wagi został pomyślnie zapisany';

  @override
  String loggedDaysLabel(int count) {
    return '$count/7 dni';
  }

  @override
  String weightAverageLabel(String weight) {
    return '$weight kg śr.';
  }

  @override
  String get editWeightTooltip => 'Edytuj wpis wagi';

  @override
  String get chartNoData => 'Brak dostępnych danych tygodniowych';

  @override
  String get chartWeeklyTrendTitle => 'Tygodniowy trend wagi';

  @override
  String get chartSingleWeekHint =>
      'Zapisz wagę w co najmniej 2 tygodniach, aby zobaczyć linię trendu';

  @override
  String get connectHevyTitle => 'Połącz treningi Hevy';

  @override
  String get connectHevySubtitle =>
      'Zaimportuj treningi z ostatnich 12 tygodni bezpośrednio z Hevy. Wygeneruj klucz API Hevy Pro na stronie https://hevy.com/settings?developer i wprowadź go poniżej.';

  @override
  String get connectHevyKeyTitle => 'Połącz klucz API Hevy';

  @override
  String get connectHevyKeySubtitle =>
      'Wygeneruj klucz API Hevy Pro na stronie https://hevy.com/settings?developer i wklej UUID poniżej.';

  @override
  String get hevyKeyInputLabel => 'Klucz API Hevy (UUID)';

  @override
  String get hevyKeyInputHint => 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

  @override
  String get connectHevyButton => 'Połącz z Hevy';

  @override
  String get saveAndConnectButton => 'Zapisz i połącz';

  @override
  String get updateApiKeyButton => 'Zaktualizuj klucz API';

  @override
  String get workoutEmptyTitle => 'Brak treningów w ostatnich 12 tygodniach';

  @override
  String get workoutEmptySubtitle =>
      'Zapisz trening w Hevy i odśwież, aby zobaczyć tygodniową objętość treningową.';

  @override
  String get refreshWorkoutsButton => 'Odśwież treningi';

  @override
  String get refreshButton => 'Odśwież';

  @override
  String last12WeeksWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'treningów',
      many: 'treningów',
      few: 'treningi',
      one: 'trening',
    );
    return 'Ostatnie 12 tygodni ($count $_temp0)';
  }

  @override
  String workoutCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'treningów',
      many: 'treningów',
      few: 'treningi',
      one: 'trening',
    );
    return '$count $_temp0';
  }

  @override
  String workoutDetailSummary(int sets, String volume) {
    return '$sets serii roboczych • $volume kg objętości';
  }

  @override
  String exerciseCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ćwiczeń',
      many: 'ćwiczeń',
      few: 'ćwiczenia',
      one: 'ćwiczenie',
    );
    return '$count $_temp0';
  }

  @override
  String workingSetsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'serii roboczych',
      many: 'serii roboczych',
      few: 'serie robocze',
      one: 'seria robocza',
    );
    return '$count $_temp0';
  }

  @override
  String get workoutNoExercises => 'Brak ćwiczeń zapisanych dla tego treningu.';

  @override
  String bestSetLabel(String performance) {
    return 'Najlepsza: $performance';
  }

  @override
  String get setTypeWarmup => 'Rozgrzewka';

  @override
  String get setTypeFailure => 'Załamanie';

  @override
  String get setTypeDropset => 'Dropset';

  @override
  String repsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'powt.',
      many: 'powt.',
      few: 'powt.',
      one: 'powt.',
    );
    return '$count $_temp0';
  }

  @override
  String minutesDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String get gainTargetTitle => 'Tygodniowy cel przyrostu wagi';

  @override
  String get gainTargetRefreshTooltip => 'Odśwież cel';

  @override
  String get gainTargetCurrentLabel => 'Aktualny cel: ';

  @override
  String get gainTargetNoTargetSet => 'Nie ustawiono celu';

  @override
  String get minWeeklyGainLabel => 'Minimalny tygodniowy przyrost';

  @override
  String get maxWeeklyGainLabel => 'Maksymalny tygodniowy przyrost';

  @override
  String get kgPerWeekUnit => 'kg/tydz.';

  @override
  String get saveTargetButton => 'Zapisz cel';

  @override
  String get gainTargetWaitingConfirmation =>
      'Oczekiwanie na potwierdzenie serwera';

  @override
  String get gainTargetSavedSuccess =>
      'Tygodniowy cel przyrostu wagi został pomyślnie zapisany';

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
