import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' hide ServerException;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/dashboard/data/datasources/pace_assessment_ai_data_source.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockGeminiContentGenerator mockGenerator;
  late PaceAssessmentAiDataSourceImpl dataSource;

  final now = DateTime.utc(2026, 4, 12, 10, 0);

  PaceAssessmentInputEntity buildInput({
    String localeCode = 'en',
    PaceAssessmentStatus baselineStatus = PaceAssessmentStatus.onTarget,
    bool isPartialWeek = true,
  }) {
    return PaceAssessmentInputEntity(
      fingerprint: 'fp_test_1',
      localeCode: localeCode,
      gainTarget: const GainTargetEntity(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.25,
      ),
      baselineStatus: baselineStatus,
      currentPaceKgPerWeek: 0.20,
      assessedWeek: AssessedWeekContextEntity(
        weekStartIso: '2026-04-06',
        weekStartMonday: DateTime.utc(2026, 4, 6),
        weekEndSunday: DateTime.utc(2026, 4, 12),
        averageWeightKg: 80.40,
        loggedWeightDaysCount: isPartialWeek ? 4 : 7,
        isCurrentWeek: true,
        isPartialWeek: isPartialWeek,
        paceKgPerWeek: 0.20,
        workoutCount: 3,
        totalWorkingSets: 18,
        totalVolumeKg: 5400.0,
        exercises: const <WeeklyExercisePerformanceEntity>[
          WeeklyExercisePerformanceEntity(
            exerciseTemplateId: 'bench_press',
            title: 'Bench Press',
            workingSetsCount: 6,
            totalVolumeKg: 2400.0,
            bestWeightKg: 100.0,
            bestReps: 8,
          ),
        ],
      ),
      priorWeeks: <AssessedWeekContextEntity>[
        AssessedWeekContextEntity(
          weekStartIso: '2026-03-23',
          weekStartMonday: DateTime.utc(2026, 3, 23),
          weekEndSunday: DateTime.utc(2026, 3, 29),
          averageWeightKg: 80.00,
          loggedWeightDaysCount: 7,
          isCurrentWeek: false,
          isPartialWeek: false,
          paceKgPerWeek: null,
          workoutCount: 0,
          totalWorkingSets: 0,
          totalVolumeKg: 0.0,
          exercises: const <WeeklyExercisePerformanceEntity>[],
        ),
        AssessedWeekContextEntity(
          weekStartIso: '2026-03-30',
          weekStartMonday: DateTime.utc(2026, 3, 30),
          weekEndSunday: DateTime.utc(2026, 4, 5),
          averageWeightKg: 80.20,
          loggedWeightDaysCount: 7,
          isCurrentWeek: false,
          isPartialWeek: false,
          paceKgPerWeek: 0.20,
          workoutCount: 2,
          totalWorkingSets: 12,
          totalVolumeKg: 4800.0,
          exercises: const <WeeklyExercisePerformanceEntity>[
            WeeklyExercisePerformanceEntity(
              exerciseTemplateId: 'bench_press',
              title: 'Bench Press',
              workingSetsCount: 6,
              totalVolumeKg: 2250.0,
              bestWeightKg: 97.5,
              bestReps: 8,
            ),
          ],
        ),
      ],
    );
  }

  String buildValidAiJson({String status = 'onTarget'}) {
    return jsonEncode(<String, Object?>{
      'status': status,
      'headlineSummary': 'Your weekly gain pace is right on target.',
      'weightTrendAnalysis':
          'Weight rose from 80.00 kg to 80.40 kg at +0.20 kg/week.',
      'workoutContextAnalysis':
          'Bench Press progressed from 97.5 kg x 8 to 100.0 kg x 8.',
      'actionableTakeaways': <String>[
        'Maintain current caloric surplus.',
        'Aim for 100 kg x 9 on Bench Press next week.',
      ],
    });
  }

  setUpAll(() {
    registerFallbackValue(PaceAssessmentAiDataSourceImpl.buildResponseSchema());
  });

  setUp(() {
    mockGenerator = MockGeminiContentGenerator();
    dataSource = PaceAssessmentAiDataSourceImpl(mockGenerator);
  });

  group('PaceAssessmentAiDataSourceImpl schema & prompt', () {
    test('buildResponseSchema defines required fields and enum values', () {
      final schema = PaceAssessmentAiDataSourceImpl.buildResponseSchema();
      final json = schema.toJson();

      expect(json['type'], 'OBJECT');
      final requiredFields = json['required'] as List<dynamic>;
      expect(
        requiredFields,
        containsAll(<String>[
          'status',
          'headlineSummary',
          'weightTrendAnalysis',
          'workoutContextAnalysis',
          'actionableTakeaways',
        ]),
      );

      final properties = json['properties'] as Map<String, dynamic>;
      final statusSchema = properties['status'] as Map<String, dynamic>;
      expect(statusSchema['format'], 'enum');
      expect(
        statusSchema['enum'],
        equals(const ['onTarget', 'tooFast', 'tooSlow', 'stagnant']),
      );

      final takeawaysSchema =
          properties['actionableTakeaways'] as Map<String, dynamic>;
      expect(takeawaysSchema['type'], 'ARRAY');
      expect(takeawaysSchema['minItems'], 2);
      expect(takeawaysSchema['maxItems'], 4);
    });

    test(
      'buildPrompt includes locale, target, baselineStatus, partial week note, rest week, and exercise best set',
      () {
        final enPrompt = PaceAssessmentAiDataSourceImpl.buildPrompt(
          buildInput(localeCode: 'en', isPartialWeek: true),
        );
        expect(enPrompt, contains('English'));
        expect(enPrompt, contains('0.15 - 0.25 kg/week'));
        expect(enPrompt, contains('baselineStatus: onTarget'));
        expect(enPrompt, contains('partial week (4/7 days logged'));
        expect(enPrompt, contains('rest/deload week'));
        expect(enPrompt, contains('Bench Press (bench_press)'));
        expect(enPrompt, contains('100.00 kg × 8 reps'));

        final plPrompt = PaceAssessmentAiDataSourceImpl.buildPrompt(
          buildInput(localeCode: 'pl', isPartialWeek: false),
        );
        expect(plPrompt, contains('Polish (polski)'));
        expect(plPrompt, contains('localeCode: pl'));
      },
    );
  });

  group('PaceAssessmentAiDataSourceImpl.generateAssessment', () {
    test('parses valid AI JSON response into PaceAssessmentDto', () async {
      when(
        () => mockGenerator.generateJson(
          prompt: any(named: 'prompt'),
          responseSchema: any(named: 'responseSchema'),
          systemInstruction: any(named: 'systemInstruction'),
        ),
      ).thenAnswer((_) async => buildValidAiJson(status: 'onTarget'));

      final input = buildInput();
      final dto = await dataSource.generateAssessment(input: input, now: now);

      expect(dto.status, 'onTarget');
      expect(dto.baselineStatus, 'onTarget');
      expect(dto.headlineSummary, 'Your weekly gain pace is right on target.');
      expect(dto.actionableTakeaways, hasLength(2));
      expect(dto.assessedWeekStartIso, '2026-04-06');
      expect(dto.isAssessedWeekPartial, isTrue);
      expect(dto.currentPaceKgPerWeek, 0.20);
      expect(dto.targetMinKgPerWeek, 0.15);
      expect(dto.targetMaxKgPerWeek, 0.25);
      expect(dto.priorWeightWeeksCount, 2);
      expect(dto.localeCode, 'en');
      expect(dto.fingerprint, 'fp_test_1');
      expect(dto.generatedAt, '2026-04-12T10:00:00.000Z');
    });

    test(
      'hybrid guardrail falls back to input.baselineStatus when AI returns unknown status string',
      () async {
        when(
          () => mockGenerator.generateJson(
            prompt: any(named: 'prompt'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
          ),
        ).thenAnswer((_) async => buildValidAiJson(status: 'unexpected_label'));

        final input = buildInput(baselineStatus: PaceAssessmentStatus.tooSlow);
        final dto = await dataSource.generateAssessment(input: input, now: now);

        expect(dto.status, 'tooSlow');
        expect(dto.baselineStatus, 'tooSlow');
      },
    );

    test(
      'throws ServerException when AI response is null, empty, or malformed JSON',
      () async {
        when(
          () => mockGenerator.generateJson(
            prompt: any(named: 'prompt'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
          ),
        ).thenAnswer((_) async => '   ');

        await expectLater(
          () => dataSource.generateAssessment(input: buildInput(), now: now),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              contains('Empty response'),
            ),
          ),
        );

        when(
          () => mockGenerator.generateJson(
            prompt: any(named: 'prompt'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
          ),
        ).thenAnswer((_) async => '{"status": "onTarget"}');

        await expectLater(
          () => dataSource.generateAssessment(input: buildInput(), now: now),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              contains('Malformed AI pace assessment response'),
            ),
          ),
        );
      },
    );

    test(
      'maps FirebaseAIException, FirebaseException, and TimeoutException appropriately',
      () async {
        when(
          () => mockGenerator.generateJson(
            prompt: any(named: 'prompt'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
          ),
        ).thenThrow(FirebaseAIException('Quota exceeded for model'));

        await expectLater(
          () => dataSource.generateAssessment(input: buildInput(), now: now),
          throwsA(isA<ServerException>()),
        );

        when(
          () => mockGenerator.generateJson(
            prompt: any(named: 'prompt'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
          ),
        ).thenThrow(
          FirebaseAIException('SocketException: Network unreachable'),
        );

        await expectLater(
          () => dataSource.generateAssessment(input: buildInput(), now: now),
          throwsA(isA<NetworkException>()),
        );

        when(
          () => mockGenerator.generateJson(
            prompt: any(named: 'prompt'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
          ),
        ).thenThrow(
          FirebaseException(
            plugin: 'app_check',
            code: 'permission-denied',
            message: 'App Check failed',
          ),
        );

        await expectLater(
          () => dataSource.generateAssessment(input: buildInput(), now: now),
          throwsA(isA<AuthException>()),
        );

        when(
          () => mockGenerator.generateJson(
            prompt: any(named: 'prompt'),
            responseSchema: any(named: 'responseSchema'),
            systemInstruction: any(named: 'systemInstruction'),
          ),
        ).thenThrow(TimeoutException('Timed out'));

        await expectLater(
          () => dataSource.generateAssessment(input: buildInput(), now: now),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              contains('AI request timed out'),
            ),
          ),
        );
      },
    );
  });
}
