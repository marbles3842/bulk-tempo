import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/providers/clock_provider.dart';
import 'package:bulk_tempo/core/providers/secure_storage_provider.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/dashboard/data/repositories/pace_assessment_repository_impl.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/pace_assessment_state.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

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
    String headlineSummary = 'Steady progress within target range.',
  }) {
    final priorCount = input.priorWeeks
        .where((w) => w.loggedWeightDaysCount > 0 && w.averageWeightKg != null)
        .length;
    return PaceAssessmentEntity(
      status: PaceAssessmentStatus.onTarget,
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
    container.listen(dashboardViewModelProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    fakeAuthRepository.dispose();
    fakeWeightRepository.reset();
    fakeWorkoutRepository.reset();
    fakeGainTargetRepository.reset();
  });

  group('DashboardViewModel state composition & initialization', () {
    test(
      'returns empty/unconfigured/ineligible state when user is unauthenticated',
      () async {
        fakeAuthRepository.setCurrentUser(null);
        await pumpEventQueue();

        final state = container.read(dashboardViewModelProvider);
        expect(state.weightStatus, equals(DashboardCardStatus.empty));
        expect(state.workoutStatus, equals(DashboardCardStatus.unconfigured));
        expect(
          state.paceAssessment.status,
          equals(PaceAssessmentViewStatus.ineligible),
        );
        expect(
          state.paceAssessment.ineligibilityReason,
          equals(PaceAssessmentIneligibilityReason.unauthenticated),
        );
      },
    );

    test(
      'ensureInitialized loads all upstream sources and composes loaded DashboardState including paceAssessment',
      () async {
        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        await container
            .read(dashboardViewModelProvider.notifier)
            .ensureInitialized();
        await pumpEventQueue();

        final state = container.read(dashboardViewModelProvider);
        expect(state.weightStatus, equals(DashboardCardStatus.loaded));
        expect(state.workoutStatus, equals(DashboardCardStatus.loaded));
        expect(state.gainTargetStatus, equals(DashboardCardStatus.loaded));
        expect(state.gainTarget, equals(defaultTarget));
        expect(state.hasAnyWorkoutInWindow, isTrue);
        expect(state.overview.currentPaceKgPerWeek, equals(0.20));
        expect(
          state.paceAssessment.status,
          equals(PaceAssessmentViewStatus.loaded),
        );
        expect(state.paceAssessment.assessment, isNotNull);
        expect(
          state.paceAssessment.assessment!.status,
          equals(PaceAssessmentStatus.onTarget),
        );
      },
    );
  });

  group('DashboardViewModel refreshAll & retryPaceAssessment coordination', () {
    test(
      'refreshAll refreshes weights, workouts, gain target, and pace assessment',
      () async {
        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        final notifier = container.read(dashboardViewModelProvider.notifier);
        await notifier.ensureInitialized();
        await pumpEventQueue();

        clearInteractions(mockPaceAssessmentRepository);

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
              headlineSummary: 'Updated on pull-to-refresh.',
            ),
          );
        });

        await notifier.refreshAll();

        final state = container.read(dashboardViewModelProvider);
        expect(
          state.paceAssessment.status,
          equals(PaceAssessmentViewStatus.loaded),
        );
        expect(
          state.paceAssessment.assessment!.headlineSummary,
          equals('Updated on pull-to-refresh.'),
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
      'retryPaceAssessment retries failed upstream data sources and triggers paceAssessment retry',
      () async {
        // Initial load fails on weight history
        fakeWeightRepository.getFailure = const NetworkFailure(
          'Weights offline',
        );
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        final notifier = container.read(dashboardViewModelProvider.notifier);
        await notifier.ensureInitialized();
        await pumpEventQueue();

        final errorState = container.read(dashboardViewModelProvider);
        expect(errorState.weightStatus, equals(DashboardCardStatus.error));
        expect(
          errorState.paceAssessment.status,
          equals(PaceAssessmentViewStatus.error),
        );
        expect(
          errorState.paceAssessment.errorMessage,
          equals('Weights offline'),
        );

        // Fix weight repository and call retryPaceAssessment
        fakeWeightRepository.getFailure = null;
        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());

        var workoutRefetches = 0;
        fakeWorkoutRepository.onGetWorkoutsForLastWeeks = () async {
          workoutRefetches++;
        };

        await notifier.retryPaceAssessment();

        final recovered = container.read(dashboardViewModelProvider);
        expect(recovered.weightStatus, equals(DashboardCardStatus.loaded));
        expect(
          recovered.paceAssessment.status,
          equals(PaceAssessmentViewStatus.loaded),
        );
        expect(recovered.paceAssessment.assessment, isNotNull);
        // Workout progress was already loaded, so it was not unnecessarily re-fetched
        expect(workoutRefetches, equals(0));
      },
    );

    test(
      'retryPaceAssessment retries paceAssessment directly when upstream sources succeeded but AI failed',
      () async {
        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async =>
              const Result.failure(ServerFailure('Gemini unavailable')),
        );

        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        final notifier = container.read(dashboardViewModelProvider.notifier);
        await notifier.ensureInitialized();
        await pumpEventQueue();

        final failedState = container.read(dashboardViewModelProvider);
        expect(failedState.weightStatus, equals(DashboardCardStatus.loaded));
        expect(failedState.workoutStatus, equals(DashboardCardStatus.loaded));
        expect(
          failedState.paceAssessment.status,
          equals(PaceAssessmentViewStatus.error),
        );
        expect(
          failedState.paceAssessment.errorMessage,
          equals('Gemini unavailable'),
        );

        var weightFetches = 0;
        fakeWeightRepository.onGetWeightEntries = () async {
          weightFetches++;
        };

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

        await notifier.retryPaceAssessment();

        final recoveredState = container.read(dashboardViewModelProvider);
        expect(
          recoveredState.paceAssessment.status,
          equals(PaceAssessmentViewStatus.loaded),
        );
        expect(recoveredState.paceAssessment.assessment, isNotNull);
        expect(weightFetches, equals(0));
      },
    );
  });
}
