import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/providers/clock_provider.dart';
import 'package:bulk_tempo/core/providers/secure_storage_provider.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/dashboard/data/repositories/pace_assessment_repository_impl.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/pace_assessment_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/pace_assessment_view_model.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_gain_target_repository.dart';
import '../../../../test_helpers/fakes/fake_weight_repository.dart';
import '../../../../test_helpers/fakes/fake_workout_repository.dart';
import '../../../../test_helpers/mocks.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeWeightRepository fakeWeightRepository;
  late FakeWorkoutRepository fakeWorkoutRepository;
  late FakeGainTargetRepository fakeGainTargetRepository;
  late MockPaceAssessmentRepository mockPaceAssessmentRepository;
  late MockFlutterSecureStorage mockSecureStorage;
  late ProviderContainer container;

  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');
  const validApiKey = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  final refNow = DateTime.utc(2026, 10, 14, 12, 0);

  const defaultTarget = GainTargetEntity(
    minWeeklyGainKg: 0.15,
    maxWeeklyGainKg: 0.25,
  );

  WeightEntryEntity createWeightEntry(String dateIso, double weightKg) {
    final parsed = DateTime.parse('${dateIso}T00:00:00.000Z');
    return WeightEntryEntity(
      dateIso: dateIso,
      date: parsed,
      weightKg: weightKg,
      updatedAt: parsed,
    );
  }

  WorkoutEntity createWorkout({
    String id = 'w1',
    String localDateIso = '2026-10-12',
    double weightKg = 80.0,
    int reps = 8,
  }) {
    final parsed = DateTime.parse('${localDateIso}T00:00:00.000Z');
    return WorkoutEntity(
      id: id,
      title: 'Upper Body $id',
      startTime: parsed.add(const Duration(hours: 10)),
      endTime: parsed.add(const Duration(hours: 11)),
      localDate: parsed,
      localDateIso: localDateIso,
      exercises: [
        WorkoutExerciseEntity(
          index: 0,
          title: 'Bench Press',
          exerciseTemplateId: 'bench_press',
          sets: [
            WorkoutSetEntity(
              index: 0,
              type: 'normal',
              weightKg: weightKg,
              reps: reps,
            ),
          ],
        ),
      ],
    );
  }

  List<WeightEntryEntity> createEligibleWeights() => [
    createWeightEntry('2026-09-28', 80.0),
    createWeightEntry('2026-10-05', 80.2),
    createWeightEntry('2026-10-12', 80.4),
  ];

  PaceAssessmentEntity buildAssessmentFromInput(
    PaceAssessmentInputEntity input, {
    PaceAssessmentStatus status = PaceAssessmentStatus.onTarget,
    String headlineSummary = 'Steady progress within target range.',
  }) {
    final priorCount = input.priorWeeks
        .where((w) => w.loggedWeightDaysCount > 0 && w.averageWeightKg != null)
        .length;
    return PaceAssessmentEntity(
      status: status,
      baselineStatus: input.baselineStatus,
      headlineSummary: headlineSummary,
      weightTrendAnalysis: 'Gaining 0.20 kg/week consistently.',
      workoutContextAnalysis: 'Bench press volume is progressing.',
      actionableTakeaways: const [
        'Maintain current caloric intake.',
        'Add 2.5 kg to bench press next week.',
      ],
      assessedWeekStartIso: input.assessedWeek.weekStartIso,
      isAssessedWeekPartial: input.assessedWeek.isPartialWeek,
      currentPaceKgPerWeek: input.currentPaceKgPerWeek,
      targetMinKgPerWeek: input.gainTarget.minWeeklyGainKg,
      targetMaxKgPerWeek: input.gainTarget.maxWeeklyGainKg,
      priorWeightWeeksCount: priorCount,
      localeCode: input.localeCode,
      fingerprint: input.fingerprint,
      generatedAt: refNow,
    );
  }

  setUpAll(() {
    registerFallbackValue(
      PaceAssessmentInputEntity(
        fingerprint: 'fallback',
        localeCode: 'en',
        gainTarget: defaultTarget,
        baselineStatus: PaceAssessmentStatus.onTarget,
        currentPaceKgPerWeek: 0.20,
        assessedWeek: AssessedWeekContextEntity(
          weekStartIso: '2026-10-12',
          weekStartMonday: DateTime.utc(2026, 10, 12),
          weekEndSunday: DateTime.utc(2026, 10, 18),
          averageWeightKg: 80.4,
          loggedWeightDaysCount: 1,
          isCurrentWeek: true,
          isPartialWeek: true,
          paceKgPerWeek: 0.20,
          workoutCount: 1,
          totalWorkingSets: 1,
          totalVolumeKg: 640.0,
          exercises: const [],
        ),
        priorWeeks: const [],
      ),
    );
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockSecureStorage = MockFlutterSecureStorage();
    when(
      () => mockSecureStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSecureStorage.deleteAll()).thenAnswer((_) async {});

    fakeAuthRepository = FakeAuthRepository(initialUser: testUser);
    fakeWeightRepository = FakeWeightRepository();
    fakeWorkoutRepository = FakeWorkoutRepository()..defaultNow = refNow;
    fakeGainTargetRepository = FakeGainTargetRepository();
    mockPaceAssessmentRepository = MockPaceAssessmentRepository();

    when(
      () => mockPaceAssessmentRepository.getOrGenerateAssessment(
        userId: any(named: 'userId'),
        input: any(named: 'input'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((invocation) async {
      final input =
          invocation.namedArguments[#input] as PaceAssessmentInputEntity;
      return Result.success(buildAssessmentFromInput(input));
    });

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
        workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
        gainTargetRepositoryProvider.overrideWithValue(
          fakeGainTargetRepository,
        ),
        paceAssessmentRepositoryProvider.overrideWithValue(
          mockPaceAssessmentRepository,
        ),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        clockProvider.overrideWithValue(() => refNow),
      ],
    );
    container.listen(paceAssessmentViewModelProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    fakeAuthRepository.dispose();
    fakeWeightRepository.reset();
    fakeWorkoutRepository.reset();
    fakeGainTargetRepository.reset();
  });

  Future<void> seedAndLoadAll({
    List<WeightEntryEntity>? weights,
    String? apiKey = validApiKey,
    List<WorkoutEntity>? workouts,
    GainTargetEntity? gainTarget = defaultTarget,
  }) async {
    if (weights != null) {
      fakeWeightRepository.seedEntries(testUser.id, weights);
    }
    if (apiKey != null) {
      fakeWorkoutRepository.seedApiKey(testUser.id, apiKey);
    }
    if (workouts != null) {
      fakeWorkoutRepository.seedWorkouts(testUser.id, workouts);
    }
    fakeGainTargetRepository.seedTarget(testUser.id, gainTarget);

    await Future.wait([
      container.read(weightHistoryViewModelProvider.notifier).loadEntries(),
      container
          .read(workoutProgressViewModelProvider.notifier)
          .loadWorkouts(now: refNow),
      container.read(gainTargetViewModelProvider.notifier).loadTarget(),
    ]);
    await pumpEventQueue();
  }

  group('Initial, unauthenticated, and upstream error states', () {
    test(
      'initial state is loading while upstream dependencies have not loaded',
      () {
        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.loading));
        expect(state.assessment, isNull);
        expect(state.errorMessage, isNull);
      },
    );

    test(
      'emits ineligible(unauthenticated) when no user is signed in',
      () async {
        fakeAuthRepository.setCurrentUser(null);
        await pumpEventQueue();

        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.ineligible));
        expect(
          state.ineligibilityReason,
          equals(PaceAssessmentIneligibilityReason.unauthenticated),
        );
      },
    );

    test(
      'emits error with upstream message when weight history fails to load',
      () async {
        fakeWeightRepository.getFailure = const ServerFailure(
          'Failed to load weights',
        );
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        await Future.wait([
          container.read(weightHistoryViewModelProvider.notifier).loadEntries(),
          container
              .read(workoutProgressViewModelProvider.notifier)
              .loadWorkouts(now: refNow),
          container.read(gainTargetViewModelProvider.notifier).loadTarget(),
        ]);
        await pumpEventQueue();

        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.error));
        expect(state.errorMessage, equals('Failed to load weights'));
        verifyNever(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        );
      },
    );

    test(
      'emits error with upstream message when workout progress fails to load',
      () async {
        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.getWorkoutsFailure = const NetworkFailure(
          'Hevy connection failed',
        );
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        await Future.wait([
          container.read(weightHistoryViewModelProvider.notifier).loadEntries(),
          container
              .read(workoutProgressViewModelProvider.notifier)
              .loadWorkouts(now: refNow),
          container.read(gainTargetViewModelProvider.notifier).loadTarget(),
        ]);
        await pumpEventQueue();

        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.error));
        expect(state.errorMessage, equals('Hevy connection failed'));
      },
    );

    test(
      'emits error with upstream message when gain target fails to load',
      () async {
        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.getFailure = const ServerFailure(
          'Gain target load error',
        );

        await Future.wait([
          container.read(weightHistoryViewModelProvider.notifier).loadEntries(),
          container
              .read(workoutProgressViewModelProvider.notifier)
              .loadWorkouts(now: refNow),
          container.read(gainTargetViewModelProvider.notifier).loadTarget(),
        ]);
        await pumpEventQueue();

        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.error));
        expect(state.errorMessage, equals('Gain target load error'));
      },
    );
  });

  group('Ineligibility states', () {
    test('emits missingGainTarget when gainTarget is null', () async {
      await seedAndLoadAll(
        weights: createEligibleWeights(),
        workouts: [createWorkout()],
        gainTarget: null,
      );

      final state = container.read(paceAssessmentViewModelProvider);
      expect(state.status, equals(PaceAssessmentViewStatus.ineligible));
      expect(
        state.ineligibilityReason,
        equals(PaceAssessmentIneligibilityReason.missingGainTarget),
      );
      expect(state.recordedWeightWeeksCount, equals(3));
      expect(state.priorWeightWeeksCount, equals(2));
      verifyNever(
        () => mockPaceAssessmentRepository.getOrGenerateAssessment(
          userId: any(named: 'userId'),
          input: any(named: 'input'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      );
    });

    test('emits workoutUnconfigured when Hevy key is not configured', () async {
      await seedAndLoadAll(
        weights: createEligibleWeights(),
        apiKey: null,
        workouts: [createWorkout()],
        gainTarget: defaultTarget,
      );

      final state = container.read(paceAssessmentViewModelProvider);
      expect(state.status, equals(PaceAssessmentViewStatus.ineligible));
      expect(
        state.ineligibilityReason,
        equals(PaceAssessmentIneligibilityReason.workoutUnconfigured),
      );
      expect(state.recordedWeightWeeksCount, equals(3));
      expect(state.priorWeightWeeksCount, equals(2));
    });

    test(
      'emits noWorkoutsInWindow when Hevy is configured but 0 workouts exist in 12-week window',
      () async {
        await seedAndLoadAll(
          weights: createEligibleWeights(),
          apiKey: validApiKey,
          workouts: const [],
          gainTarget: defaultTarget,
        );

        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.ineligible));
        expect(
          state.ineligibilityReason,
          equals(PaceAssessmentIneligibilityReason.noWorkoutsInWindow),
        );
        expect(state.recordedWeightWeeksCount, equals(3));
        expect(state.priorWeightWeeksCount, equals(2));
      },
    );

    test(
      'emits insufficientWeightWeeks when fewer than 2 prior weight weeks exist',
      () async {
        await seedAndLoadAll(
          weights: [
            createWeightEntry('2026-10-05', 80.2),
            createWeightEntry('2026-10-12', 80.4),
          ],
          apiKey: validApiKey,
          workouts: [createWorkout()],
          gainTarget: defaultTarget,
        );

        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.ineligible));
        expect(
          state.ineligibilityReason,
          equals(PaceAssessmentIneligibilityReason.insufficientWeightWeeks),
        );
        expect(state.recordedWeightWeeksCount, equals(2));
        expect(state.priorWeightWeeksCount, equals(1));
      },
    );
  });

  group('Automatic evaluation, fingerprint deduplication & locale switch', () {
    test(
      'automatically evaluates and transitions to loaded when eligible',
      () async {
        await seedAndLoadAll(
          weights: createEligibleWeights(),
          workouts: [createWorkout()],
          gainTarget: defaultTarget,
        );

        final state = container.read(paceAssessmentViewModelProvider);
        expect(state.status, equals(PaceAssessmentViewStatus.loaded));
        expect(state.assessment, isNotNull);
        expect(state.assessment!.status, equals(PaceAssessmentStatus.onTarget));
        expect(state.recordedWeightWeeksCount, equals(3));
        expect(state.priorWeightWeeksCount, equals(2));
        expect(state.isRefreshing, isFalse);
        expect(state.isOutdated, isFalse);
        expect(state.errorMessage, isNull);
        expect(
          state.lastEvaluatedFingerprint,
          equals(state.assessment!.fingerprint),
        );

        verify(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: testUser.id,
            input: any(named: 'input'),
            forceRefresh: false,
          ),
        ).called(1);
      },
    );

    test(
      'deduplicates identical fingerprints across upstream draft updates or unchanged reloads',
      () async {
        await seedAndLoadAll(
          weights: createEligibleWeights(),
          workouts: [createWorkout()],
          gainTarget: defaultTarget,
        );

        verify(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: testUser.id,
            input: any(named: 'input'),
            forceRefresh: false,
          ),
        ).called(1);

        // Editing draft gain target input without saving does not alter savedTarget or fingerprint
        container
            .read(gainTargetViewModelProvider.notifier)
            .updateMinInput('0.18');
        await pumpEventQueue();

        // Reloading weights with identical entries produces the same fingerprint
        await container
            .read(weightHistoryViewModelProvider.notifier)
            .loadEntries(showLoading: false);
        await pumpEventQueue();

        verifyNever(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        );
        expect(
          container.read(paceAssessmentViewModelProvider).status,
          equals(PaceAssessmentViewStatus.loaded),
        );
      },
    );

    test(
      'switching locale triggers automatic re-evaluation with updated localeCode and fingerprint',
      () async {
        await seedAndLoadAll(
          weights: createEligibleWeights(),
          workouts: [createWorkout()],
          gainTarget: defaultTarget,
        );

        final enState = container.read(paceAssessmentViewModelProvider);
        expect(enState.status, equals(PaceAssessmentViewStatus.loaded));
        expect(enState.assessment!.localeCode, equals('en'));

        // Switch locale to Polish
        await container
            .read(localeProvider.notifier)
            .setLocale(const Locale('pl'));
        await pumpEventQueue();

        final plState = container.read(paceAssessmentViewModelProvider);
        expect(plState.status, equals(PaceAssessmentViewStatus.loaded));
        expect(plState.assessment!.localeCode, equals('pl'));
        expect(
          plState.assessment!.fingerprint,
          isNot(equals(enState.assessment!.fingerprint)),
        );

        verify(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: testUser.id,
            input: any(named: 'input'),
            forceRefresh: false,
          ),
        ).called(2);
      },
    );

    test(
      'applying a new weight entry changes fingerprint and triggers re-evaluation',
      () async {
        await seedAndLoadAll(
          weights: createEligibleWeights(),
          workouts: [createWorkout()],
          gainTarget: defaultTarget,
        );

        final initialFp = container
            .read(paceAssessmentViewModelProvider)
            .assessment!
            .fingerprint;

        container
            .read(weightHistoryViewModelProvider.notifier)
            .applySavedEntry(
              userId: testUser.id,
              entry: createWeightEntry('2026-10-13', 80.8),
            );
        await pumpEventQueue();

        final updatedState = container.read(paceAssessmentViewModelProvider);
        expect(updatedState.status, equals(PaceAssessmentViewStatus.loaded));
        expect(updatedState.assessment!.fingerprint, isNot(equals(initialFp)));
        verify(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: testUser.id,
            input: any(named: 'input'),
            forceRefresh: false,
          ),
        ).called(2);
      },
    );
  });

  group('Error recovery, refresh, and outdated state handling', () {
    test(
      'initial evaluation failure emits error status and retry() recovers to loaded',
      () async {
        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => const Result.failure(
            ServerFailure('AI quota temporarily exceeded'),
          ),
        );

        await seedAndLoadAll(
          weights: createEligibleWeights(),
          workouts: [createWorkout()],
          gainTarget: defaultTarget,
        );

        final errorState = container.read(paceAssessmentViewModelProvider);
        expect(errorState.status, equals(PaceAssessmentViewStatus.error));
        expect(
          errorState.errorMessage,
          equals('AI quota temporarily exceeded'),
        );
        expect(errorState.assessment, isNull);
        expect(errorState.lastEvaluatedFingerprint, isNotNull);

        // Stub success and retry
        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((invocation) async {
          final input =
              invocation.namedArguments[#input] as PaceAssessmentInputEntity;
          return Result.success(buildAssessmentFromInput(input));
        });

        await container.read(paceAssessmentViewModelProvider.notifier).retry();

        final recoveredState = container.read(paceAssessmentViewModelProvider);
        expect(recoveredState.status, equals(PaceAssessmentViewStatus.loaded));
        expect(recoveredState.assessment, isNotNull);
        expect(recoveredState.errorMessage, isNull);
      },
    );

    test(
      'refresh Failure while assessment is already displayed preserves loaded status, sets isOutdated: true, and populates refreshErrorMessage',
      () async {
        await seedAndLoadAll(
          weights: createEligibleWeights(),
          workouts: [createWorkout()],
          gainTarget: defaultTarget,
        );

        final initialLoaded = container.read(paceAssessmentViewModelProvider);
        expect(initialLoaded.status, equals(PaceAssessmentViewStatus.loaded));
        expect(initialLoaded.assessment, isNotNull);

        // Next call fails
        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => const Result.failure(NetworkFailure('Offline')),
        );

        await container
            .read(paceAssessmentViewModelProvider.notifier)
            .refresh(forceRefresh: true);

        final outdatedState = container.read(paceAssessmentViewModelProvider);
        expect(outdatedState.status, equals(PaceAssessmentViewStatus.loaded));
        expect(outdatedState.assessment, equals(initialLoaded.assessment));
        expect(outdatedState.isOutdated, isTrue);
        expect(outdatedState.isRefreshing, isFalse);
        expect(outdatedState.refreshErrorMessage, equals('Offline'));
        expect(outdatedState.errorMessage, isNull);

        verify(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: testUser.id,
            input: any(named: 'input'),
            forceRefresh: true,
          ),
        ).called(1);

        // Subsequent retry clears outdated flag and refreshErrorMessage
        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((invocation) async {
          final input =
              invocation.namedArguments[#input] as PaceAssessmentInputEntity;
          return Result.success(
            buildAssessmentFromInput(
              input,
              headlineSummary: 'Refreshed summary.',
            ),
          );
        });

        await container.read(paceAssessmentViewModelProvider.notifier).retry();

        final freshState = container.read(paceAssessmentViewModelProvider);
        expect(freshState.status, equals(PaceAssessmentViewStatus.loaded));
        expect(
          freshState.assessment!.headlineSummary,
          equals('Refreshed summary.'),
        );
        expect(freshState.isOutdated, isFalse);
        expect(freshState.refreshErrorMessage, isNull);
      },
    );
  });

  group('Account switch isolation & race/disposal guards', () {
    test(
      'account switch resets state and drops in-flight evaluation from previous user',
      () async {
        final completer = Completer<Result<PaceAssessmentEntity, AppFailure>>();
        PaceAssessmentInputEntity? capturedInput;

        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((invocation) {
          capturedInput =
              invocation.namedArguments[#input] as PaceAssessmentInputEntity;
          return completer.future;
        });

        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        await Future.wait([
          container.read(weightHistoryViewModelProvider.notifier).loadEntries(),
          container
              .read(workoutProgressViewModelProvider.notifier)
              .loadWorkouts(now: refNow),
          container.read(gainTargetViewModelProvider.notifier).loadTarget(),
        ]);
        await pumpEventQueue();

        expect(capturedInput, isNotNull);
        expect(
          container.read(paceAssessmentViewModelProvider).status,
          equals(PaceAssessmentViewStatus.loading),
        );

        // Switch user to u2 while u1's evaluation is in flight
        fakeAuthRepository.setCurrentUser(
          const UserEntity(id: 'u2', email: 'other@example.com'),
        );
        await pumpEventQueue();

        // Complete u1's in-flight evaluation
        completer.complete(
          Result.success(buildAssessmentFromInput(capturedInput!)),
        );
        await pumpEventQueue();

        // u2 must NOT have u1's assessment
        final u2State = container.read(paceAssessmentViewModelProvider);
        expect(u2State.assessment, isNull);
        expect(u2State.status, equals(PaceAssessmentViewStatus.loading));
      },
    );

    test(
      'disposing container during in-flight evaluation does not throw',
      () async {
        final completer = Completer<Result<PaceAssessmentEntity, AppFailure>>();
        PaceAssessmentInputEntity? capturedInput;

        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((invocation) {
          capturedInput =
              invocation.namedArguments[#input] as PaceAssessmentInputEntity;
          return completer.future;
        });

        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
            paceAssessmentRepositoryProvider.overrideWithValue(
              mockPaceAssessmentRepository,
            ),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
            clockProvider.overrideWithValue(() => refNow),
          ],
        );
        localContainer.listen(paceAssessmentViewModelProvider, (_, _) {});

        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        await Future.wait([
          localContainer
              .read(weightHistoryViewModelProvider.notifier)
              .loadEntries(),
          localContainer
              .read(workoutProgressViewModelProvider.notifier)
              .loadWorkouts(now: refNow),
          localContainer
              .read(gainTargetViewModelProvider.notifier)
              .loadTarget(),
        ]);
        await pumpEventQueue();

        expect(capturedInput, isNotNull);

        localContainer.dispose();
        completer.complete(
          Result.success(buildAssessmentFromInput(capturedInput!)),
        );
        await pumpEventQueue();
      },
    );
  });
}
