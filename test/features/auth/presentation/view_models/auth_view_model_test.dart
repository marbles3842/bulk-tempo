import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/localization/locale_notifier.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_state.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_form_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_view_model.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_form_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/mocks.dart';

class _FakeWorkoutProgressViewModel extends WorkoutProgressViewModel {
  final VoidCallback? onBuild;
  _FakeWorkoutProgressViewModel({this.onBuild});

  @override
  WorkoutProgressState build() {
    onBuild?.call();
    return const WorkoutProgressState.initial();
  }
}

class _FakeHevyKeyViewModel extends HevyKeyViewModel {
  final VoidCallback? onBuild;
  _FakeHevyKeyViewModel({this.onBuild});

  @override
  HevyKeyFormState build() {
    onBuild?.call();
    return const HevyKeyFormState();
  }
}

class _FakeWeightHistoryViewModel extends WeightHistoryViewModel {
  final VoidCallback? onBuild;
  _FakeWeightHistoryViewModel({this.onBuild});

  @override
  WeightHistoryState build() {
    onBuild?.call();
    return const WeightHistoryInitial();
  }
}

class _FakeWeightEntryViewModel extends WeightEntryViewModel {
  final VoidCallback? onBuild;
  _FakeWeightEntryViewModel({this.onBuild});

  @override
  WeightEntryFormState build() {
    onBuild?.call();
    return WeightEntryFormState(selectedDate: DateTime.utc(2026, 1, 1));
  }
}

class _FakeGainTargetViewModel extends GainTargetViewModel {
  final VoidCallback? onBuild;
  _FakeGainTargetViewModel({this.onBuild});

  @override
  GainTargetState build() {
    onBuild?.call();
    return const GainTargetState();
  }
}

class _FakeDashboardViewModel extends DashboardViewModel {
  final VoidCallback? onBuild;
  _FakeDashboardViewModel({this.onBuild});

  @override
  DashboardState build() {
    onBuild?.call();
    return const DashboardState(
      weightStatus: DashboardCardStatus.empty,
      workoutStatus: DashboardCardStatus.unconfigured,
      overview: WeeklyProgressOverviewEntity(
        calendarWeeks: [],
        latestWeekLoggedDays: 0,
        isLatestWeekCurrentWeek: false,
        isLatestWeekIncomplete: false,
        currentWeekWorkoutCount: 0,
        loggedWeightWeeksCount: 0,
      ),
    );
  }
}

class _FakeLocaleNotifier extends LocaleNotifier {
  final VoidCallback? onBuild;
  _FakeLocaleNotifier({this.onBuild});

  @override
  Locale build() {
    onBuild?.call();
    return const Locale('en');
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late MockFlutterSecureStorage mockStorage;
  late ProviderContainer container;

  const testUser = UserEntity(id: 'u1', email: 'test@example.com');

  setUp(() {
    fakeRepository = FakeAuthRepository();
    mockStorage = MockFlutterSecureStorage();
    when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    fakeRepository.dispose();
  });

  test('initial state has isInitializing true', () {
    final state = container.read(authViewModelProvider);
    expect(state.isInitializing, isTrue);
    expect(state.user, isNull);
    expect(state.isAuthenticated, isFalse);
  });

  test(
    'updates user and isInitializing when repository emits auth state',
    () async {
      // Read the provider to subscribe
      container.read(authViewModelProvider);

      // Emit a user via repository
      fakeRepository.setCurrentUser(testUser);
      // Allow stream microtasks to pump
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authViewModelProvider);
      expect(state.isInitializing, isFalse);
      expect(state.user, equals(testUser));
      expect(state.isAuthenticated, isTrue);
    },
  );

  test(
    'signOut calls storage.deleteAll() and clears user state on success',
    () async {
      fakeRepository.setCurrentUser(testUser);
      container.read(authViewModelProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authViewModelProvider).user, equals(testUser));

      await container.read(authViewModelProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      verify(() => mockStorage.deleteAll()).called(1);
      final state = container.read(authViewModelProvider);
      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNull);
    },
  );

  test(
    'signOut proceeds with sign-out even if storage.deleteAll() throws (fail-open)',
    () async {
      fakeRepository.setCurrentUser(testUser);
      container.read(authViewModelProvider);
      await Future<void>.delayed(Duration.zero);

      when(
        () => mockStorage.deleteAll(),
      ).thenThrow(Exception('Keystore failure'));

      await container.read(authViewModelProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      verify(() => mockStorage.deleteAll()).called(1);
      final state = container.read(authViewModelProvider);
      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNull);
    },
  );

  test(
    'signOut invalidates workout, weight, target, dashboard, and locale providers',
    () async {
      int workoutProgressBuilds = 0;
      int hevyKeyBuilds = 0;
      int weightHistoryBuilds = 0;
      int weightEntryBuilds = 0;
      int gainTargetBuilds = 0;
      int dashboardBuilds = 0;
      int localeBuilds = 0;

      final testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          secureStorageProvider.overrideWithValue(mockStorage),
          workoutProgressViewModelProvider.overrideWith(() {
            return _FakeWorkoutProgressViewModel(
              onBuild: () => workoutProgressBuilds++,
            );
          }),
          hevyKeyViewModelProvider.overrideWith(() {
            return _FakeHevyKeyViewModel(onBuild: () => hevyKeyBuilds++);
          }),
          weightHistoryViewModelProvider.overrideWith(() {
            return _FakeWeightHistoryViewModel(
              onBuild: () => weightHistoryBuilds++,
            );
          }),
          weightEntryViewModelProvider.overrideWith(() {
            return _FakeWeightEntryViewModel(
              onBuild: () => weightEntryBuilds++,
            );
          }),
          gainTargetViewModelProvider.overrideWith(() {
            return _FakeGainTargetViewModel(onBuild: () => gainTargetBuilds++);
          }),
          dashboardViewModelProvider.overrideWith(() {
            return _FakeDashboardViewModel(onBuild: () => dashboardBuilds++);
          }),
          localeProvider.overrideWith(() {
            return _FakeLocaleNotifier(onBuild: () => localeBuilds++);
          }),
        ],
      );
      addTearDown(testContainer.dispose);

      final subs = [
        testContainer.listen(
          workoutProgressViewModelProvider,
          (previous, next) {},
        ),
        testContainer.listen(hevyKeyViewModelProvider, (previous, next) {}),
        testContainer.listen(
          weightHistoryViewModelProvider,
          (previous, next) {},
        ),
        testContainer.listen(weightEntryViewModelProvider, (previous, next) {}),
        testContainer.listen(gainTargetViewModelProvider, (previous, next) {}),
        testContainer.listen(dashboardViewModelProvider, (previous, next) {}),
        testContainer.listen(localeProvider, (previous, next) {}),
      ];
      for (final sub in subs) {
        addTearDown(sub.close);
      }

      expect(workoutProgressBuilds, equals(1));
      expect(hevyKeyBuilds, equals(1));
      expect(weightHistoryBuilds, equals(1));
      expect(weightEntryBuilds, equals(1));
      expect(gainTargetBuilds, equals(1));
      expect(dashboardBuilds, equals(1));
      expect(localeBuilds, equals(1));

      fakeRepository.setCurrentUser(testUser);
      testContainer.read(authViewModelProvider);
      await Future<void>.delayed(Duration.zero);

      await testContainer.read(authViewModelProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      testContainer.read(workoutProgressViewModelProvider);
      testContainer.read(hevyKeyViewModelProvider);
      testContainer.read(weightHistoryViewModelProvider);
      testContainer.read(weightEntryViewModelProvider);
      testContainer.read(gainTargetViewModelProvider);
      testContainer.read(dashboardViewModelProvider);
      testContainer.read(localeProvider);

      expect(workoutProgressBuilds, equals(2));
      expect(hevyKeyBuilds, equals(2));
      expect(weightHistoryBuilds, equals(2));
      expect(weightEntryBuilds, equals(2));
      expect(gainTargetBuilds, equals(2));
      expect(dashboardBuilds, equals(2));
      expect(localeBuilds, equals(2));
    },
  );

  test('signOut sets errorMessage on failure', () async {
    fakeRepository.setCurrentUser(testUser);
    container.read(authViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    fakeRepository.signOutFailure = const ServerFailure('Sign out failed');

    await container.read(authViewModelProvider.notifier).signOut();

    final state = container.read(authViewModelProvider);
    expect(state.errorMessage, equals('Sign out failed'));
  });

  test('clearError resets errorMessage to null', () async {
    fakeRepository.setCurrentUser(testUser);
    container.read(authViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    fakeRepository.signOutFailure = const ServerFailure('Sign out failed');
    await container.read(authViewModelProvider.notifier).signOut();

    expect(
      container.read(authViewModelProvider).errorMessage,
      equals('Sign out failed'),
    );

    container.read(authViewModelProvider.notifier).clearError();
    expect(container.read(authViewModelProvider).errorMessage, isNull);
  });

  test(
    'handles stream error by clearing initialization and setting errorMessage',
    () async {
      final mockRepo = MockAuthRepository();
      when(() => mockRepo.currentUser).thenReturn(null);
      when(() => mockRepo.authStateChanges()).thenAnswer(
        (_) => Stream<UserEntity?>.error(Exception('Stream failed')),
      );

      final errorContainer = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(errorContainer.dispose);

      final initialState = errorContainer.read(authViewModelProvider);
      expect(initialState.isInitializing, isTrue);

      await Future<void>.delayed(Duration.zero);

      final state = errorContainer.read(authViewModelProvider);
      expect(state.isInitializing, isFalse);
      expect(state.user, isNull);
      expect(
        state.errorMessage,
        equals('Failed to verify authentication status. Please try again.'),
      );
    },
  );
}
