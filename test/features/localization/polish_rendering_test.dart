import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/auth/presentation/views/home_shell_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/login_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/register_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/splash_screen.dart';
import 'package:bulk_tempo/features/weight/presentation/views/weight_history_view.dart';
import 'package:bulk_tempo/features/workout/presentation/views/workout_progress_view.dart';
import 'package:bulk_tempo/features/gain_target/presentation/views/gain_target_view.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';

import '../../test_helpers/fakes/fake_auth_repository.dart';
import '../../test_helpers/fakes/fake_gain_target_repository.dart';
import '../../test_helpers/fakes/fake_weight_repository.dart';
import '../../test_helpers/fakes/fake_workout_repository.dart';
import '../../test_helpers/pump_app.dart';

void main() {
  group('Polish Presentation Localizations', () {
    late FakeAuthRepository unauthRepository;
    late FakeAuthRepository authRepository;
    late FakeWeightRepository fakeWeightRepository;
    late FakeWorkoutRepository fakeWorkoutRepository;
    late FakeGainTargetRepository fakeGainTargetRepository;

    const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');

    setUp(() {
      unauthRepository = FakeAuthRepository();
      authRepository = FakeAuthRepository(initialUser: testUser);
      fakeWeightRepository = FakeWeightRepository();
      fakeWorkoutRepository = FakeWorkoutRepository();
      fakeGainTargetRepository = FakeGainTargetRepository();
    });

    tearDown(() {
      unauthRepository.dispose();
      authRepository.dispose();
      fakeWeightRepository.reset();
      fakeWorkoutRepository.reset();
      fakeGainTargetRepository.reset();
    });

    testWidgets('renders login screen in Polish', (tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        locale: const Locale('pl'),
        overrides: [authRepositoryProvider.overrideWithValue(unauthRepository)],
      );

      expect(find.text('Witaj ponownie'), findsOneWidget);
      expect(
        find.text('Zaloguj się, aby uzyskać dostęp do swoich treningów'),
        findsOneWidget,
      );
      expect(find.text('Adres e-mail'), findsOneWidget);
      expect(find.text('Hasło'), findsOneWidget);
      expect(find.text('Zaloguj się'), findsOneWidget);
      expect(find.text('Nie masz konta? Zarejestruj się'), findsOneWidget);
      expect(find.byTooltip('Pokaż hasło'), findsOneWidget);
    });

    testWidgets('renders register screen in Polish', (tester) async {
      await tester.pumpApp(
        const RegisterScreen(),
        locale: const Locale('pl'),
        overrides: [authRepositoryProvider.overrideWithValue(unauthRepository)],
      );

      expect(find.text('Utwórz konto'), findsNWidgets(2));
      expect(
        find.text('Zacznij śledzić swoje treningi już dziś'),
        findsOneWidget,
      );
      expect(find.text('Adres e-mail'), findsOneWidget);
      expect(find.text('Hasło'), findsOneWidget);
      expect(find.text('Masz już konto? Zaloguj się'), findsOneWidget);
    });

    testWidgets('renders splash screen with app title', (tester) async {
      await tester.pumpApp(const SplashScreen(), locale: const Locale('pl'));

      expect(find.text('Bulk Tempo'), findsOneWidget);
    });

    testWidgets('renders weight history empty state in Polish', (tester) async {
      await tester.pumpApp(
        const WeightHistoryView(),
        locale: const Locale('pl'),
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Brak wpisów wagi'), findsOneWidget);
      expect(
        find.text('Regularnie zapisuj wagę, aby obserwować trendy w czasie.'),
        findsOneWidget,
      );
      expect(find.text('Dodaj pierwszą wagę'), findsOneWidget);
      expect(find.text('Dodaj wagę'), findsOneWidget);
    });

    testWidgets('renders workout progress unconfigured state in Polish', (
      tester,
    ) async {
      await tester.pumpApp(
        const WorkoutProgressView(),
        locale: const Locale('pl'),
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Połącz treningi Hevy'), findsOneWidget);
      expect(find.text('Klucz API Hevy (UUID)'), findsOneWidget);
      expect(find.text('Połącz z Hevy'), findsOneWidget);
    });

    testWidgets('renders gain target view in Polish', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: GainTargetView(),
            ),
          ),
        ),
        locale: const Locale('pl'),
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          gainTargetRepositoryProvider.overrideWithValue(
            fakeGainTargetRepository,
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Tygodniowy cel przyrostu wagi'), findsOneWidget);
      expect(find.text('Aktualny cel: '), findsOneWidget);
      expect(find.text('Nie ustawiono celu'), findsOneWidget);
      expect(find.text('Minimalny tygodniowy przyrost'), findsOneWidget);
      expect(find.text('Maksymalny tygodniowy przyrost'), findsOneWidget);
      expect(find.text('Zapisz cel'), findsOneWidget);
    });

    testWidgets('renders home dashboard view in Polish', (tester) async {
      await tester.pumpApp(
        const HomeShellScreen(),
        locale: const Locale('pl'),
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          gainTargetRepositoryProvider.overrideWithValue(
            fakeGainTargetRepository,
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Bieżące tempo'), findsOneWidget);
      expect(find.text('Ostatnia średnia'), findsOneWidget);
      expect(find.text('Łączny przyrost'), findsOneWidget);
      expect(find.text('Treningi w tym tygodniu'), findsOneWidget);
      expect(find.text('Tygodniowy trend wagi'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Tygodniowe tempo'), 100);
      expect(find.text('Tygodniowe tempo'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Liczba treningów na tydzień'),
        100,
      );
      expect(find.text('Liczba treningów na tydzień'), findsOneWidget);
    });
  });
}
