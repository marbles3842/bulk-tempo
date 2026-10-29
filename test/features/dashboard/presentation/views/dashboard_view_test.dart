import 'package:flutter/material.dart';
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
import 'package:bulk_tempo/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/pace_assessment_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/pace_assessment_report_bottom_sheet.dart';
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
import '../../../../test_helpers/pump_app.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeWeightRepository fakeWeightRepository;
  late FakeWorkoutRepository fakeWorkoutRepository;
  late FakeGainTargetRepository fakeGainTargetRepository;
  late MockPaceAssessmentRepository mockPaceAssessmentRepository;
  late MockFlutterSecureStorage mockSecureStorage;

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
  }) {
    final parsed = DateTime.parse('${localDateIso}T00:00:00.000Z');
    return WorkoutEntity(
      id: id,
      title: 'Upper Body $id',
      startTime: parsed.add(const Duration(hours: 10)),
      endTime: parsed.add(const Duration(hours: 11)),
      localDate: parsed,
      localDateIso: localDateIso,
      exercises: const [
        WorkoutExerciseEntity(
          index: 0,
          title: 'Bench Press',
          exerciseTemplateId: 'bench_press',
          sets: [
            WorkoutSetEntity(
              index: 0,
              type: 'normal',
              weightKg: 100.0,
              reps: 8,
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
    String headlineSummary = 'Weight gain is right on target.',
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
          totalVolumeKg: 800.0,
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
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    fakeWeightRepository.reset();
    fakeWorkoutRepository.reset();
    fakeGainTargetRepository.reset();
  });

  List<Override> buildOverrides() => [
    authRepositoryProvider.overrideWithValue(fakeAuthRepository),
    weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
    workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
    gainTargetRepositoryProvider.overrideWithValue(fakeGainTargetRepository),
    paceAssessmentRepositoryProvider.overrideWithValue(
      mockPaceAssessmentRepository,
    ),
    secureStorageProvider.overrideWithValue(mockSecureStorage),
    clockProvider.overrideWithValue(() => refNow),
  ];

  group('DashboardView with PaceAssessmentCard', () {
    testWidgets(
      'renders PaceAssessmentCard at the top above DashboardKpiRow and shows missingGainTarget message when target is not set',
      (tester) async {
        await tester.pumpApp(
          const Scaffold(body: DashboardView()),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PaceAssessmentCard), findsOneWidget);
        expect(
          find.byKey(const Key('dashboard_pace_assessment_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('pace_assessment_ineligible_text')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Set your weekly gain target in Profile to unlock AI pace assessment.',
          ),
          findsOneWidget,
        );

        final cardTop = tester
            .getTopLeft(find.byKey(const Key('dashboard_pace_assessment_card')))
            .dy;
        final kpiTop = tester
            .getTopLeft(find.byKey(const Key('dashboard_kpi_pace_tile')))
            .dy;
        expect(cardTop, lessThan(kpiTop));
      },
    );

    testWidgets(
      'renders loaded AI assessment, supports refresh, and opens PaceAssessmentReportBottomSheet when View Full AI Report is tapped',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        await tester.pumpApp(
          const Scaffold(body: DashboardView()),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('pace_assessment_status_badge')),
          findsOneWidget,
        );
        expect(find.text('On target'), findsOneWidget);
        expect(find.text('Weight gain is right on target.'), findsOneWidget);

        // Tap refresh button
        await tester.tap(
          find.byKey(const Key('pace_assessment_refresh_button')),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: testUser.id,
            input: any(named: 'input'),
            forceRefresh: true,
          ),
        ).called(1);

        // Tap View Full AI Report button
        await tester.tap(
          find.byKey(const Key('pace_assessment_view_report_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PaceAssessmentReportBottomSheet), findsOneWidget);
        expect(find.text('AI Pace Assessment Report'), findsOneWidget);
        expect(
          find.byKey(const Key('pace_report_weight_section')),
          findsOneWidget,
        );
        expect(find.text('Gaining 0.20 kg/week consistently.'), findsOneWidget);
        expect(
          find.byKey(const Key('pace_report_workout_section')),
          findsOneWidget,
        );

        // Close modal bottom sheet
        await tester.tap(find.byKey(const Key('pace_report_close_button')));
        await tester.pumpAndSettle();

        expect(find.byType(PaceAssessmentReportBottomSheet), findsNothing);
      },
    );

    testWidgets(
      'tapping Retry on PaceAssessmentCard recovers from AI error state',
      (tester) async {
        when(
          () => mockPaceAssessmentRepository.getOrGenerateAssessment(
            userId: any(named: 'userId'),
            input: any(named: 'input'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async =>
              const Result.failure(ServerFailure('AI service unavailable')),
        );

        fakeWeightRepository.seedEntries(testUser.id, createEligibleWeights());
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [createWorkout()]);
        fakeGainTargetRepository.seedTarget(testUser.id, defaultTarget);

        await tester.pumpApp(
          const Scaffold(body: DashboardView()),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        expect(find.text('AI service unavailable'), findsOneWidget);
        expect(
          find.byKey(const Key('pace_assessment_retry_button')),
          findsOneWidget,
        );

        // Stub success and tap Retry
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
              headlineSummary: 'Recovered AI assessment.',
            ),
          );
        });

        await tester.tap(find.byKey(const Key('pace_assessment_retry_button')));
        await tester.pumpAndSettle();

        expect(find.text('Recovered AI assessment.'), findsOneWidget);
      },
    );
  });
}
