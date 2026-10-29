import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart' hide ServerException;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/dashboard/data/models/pace_assessment_dto.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';

final geminiContentGeneratorProvider = Provider<GeminiContentGenerator>((ref) {
  return FirebaseAiContentGenerator();
});

final paceAssessmentAiDataSourceProvider = Provider<PaceAssessmentAiDataSource>(
  (ref) {
    final generator = ref.watch(geminiContentGeneratorProvider);
    return PaceAssessmentAiDataSourceImpl(generator);
  },
);

/// Mockable adapter wrapping `GenerativeModel.generateContent` from `firebase_ai`.
abstract class GeminiContentGenerator {
  Future<String?> generateJson({
    required String prompt,
    required Schema responseSchema,
    String? systemInstruction,
  });
}

/// Production implementation of [GeminiContentGenerator] backed by
/// `gemini-3.5-flash-lite` via `FirebaseAI.googleAI()`, with automatic fallback
/// to `gemini-3.5-flash` if the primary model experiences transient errors.
class FirebaseAiContentGenerator implements GeminiContentGenerator {
  static const String modelName = 'gemini-3.5-flash-lite';
  static const String fallbackModelName = 'gemini-3.5-flash';

  @override
  Future<String?> generateJson({
    required String prompt,
    required Schema responseSchema,
    String? systemInstruction,
  }) async {
    try {
      return await _generateWithModel(
        model: modelName,
        prompt: prompt,
        responseSchema: responseSchema,
        systemInstruction: systemInstruction,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      final lower = e.toString().toLowerCase();
      final isTransientModelOverload =
          e is TimeoutException ||
          lower.contains('high demand') ||
          lower.contains('deadline expired') ||
          lower.contains('500') ||
          lower.contains('503') ||
          lower.contains('overloaded') ||
          lower.contains('unavailable');
      if (!isTransientModelOverload) {
        rethrow;
      }
      return _generateWithModel(
        model: fallbackModelName,
        prompt: prompt,
        responseSchema: responseSchema,
        systemInstruction: systemInstruction,
      );
    }
  }

  Future<String?> _generateWithModel({
    required String model,
    required String prompt,
    required Schema responseSchema,
    String? systemInstruction,
  }) async {
    final generativeModel =
        FirebaseAI.googleAI(
          auth: FirebaseAuth.instance,
          appCheck: FirebaseAppCheck.instance,
        ).generativeModel(
          model: model,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: responseSchema,
          ),
          systemInstruction: systemInstruction != null
              ? Content.system(systemInstruction)
              : null,
        );

    final response = await generativeModel.generateContent([
      Content.text(prompt),
    ]);
    return response.text;
  }
}

abstract class PaceAssessmentAiDataSource {
  Future<PaceAssessmentDto> generateAssessment({
    required PaceAssessmentInputEntity input,
    required DateTime now,
  });
}

class PaceAssessmentAiDataSourceImpl implements PaceAssessmentAiDataSource {
  final GeminiContentGenerator _generator;

  PaceAssessmentAiDataSourceImpl(this._generator);

  static const String _systemInstruction =
      'You are an evidence-based strength and hypertrophy coaching analyst for a clean-bulking mobile app. '
      'Evaluate weekly weight-gain pace in the context of multi-week weight trends and Hevy workout progression '
      '(weights, repetitions, and working volume). '
      'Hybrid status guardrail: Always start from the provided deterministic baselineStatus ('
      'stagnant when pace <= 0.0, tooSlow when 0.0 < pace < targetMin, onTarget when targetMin <= pace <= targetMax, '
      'tooFast when pace > targetMax). Only adjust borderline cases when multi-week weight trend and workout '
      'progression strongly justify it (for example, distinguishing stagnant vs tooSlow based on whether strength '
      'and working volume are progressing or stalled, or recognizing a partial current week distortion). '
      'Never calculate calorie or macro targets; focus strictly on interpreting weight pace and training progression.';

  /// Builds the structured output [Schema] required for Gemini JSON generation.
  static Schema buildResponseSchema() {
    return Schema.object(
      properties: {
        'status': Schema.enumString(
          enumValues: const ['onTarget', 'tooFast', 'tooSlow', 'stagnant'],
          description:
              'Final pace classification status starting from baselineStatus and adjusted only if borderline multi-week trend and workout progression strongly justify it.',
        ),
        'headlineSummary': Schema.string(
          description:
              'Concise 1-2 sentence summary for the Dashboard card explaining the pace assessment and training context.',
        ),
        'weightTrendAnalysis': Schema.string(
          description:
              'Detailed analysis of the assessed week pace and prior weeks weight trend compared against the target weekly gain range.',
        ),
        'workoutContextAnalysis': Schema.string(
          description:
              'Detailed analysis of workout frequency, working sets, volume, and exercise weight x reps progression across weeks (treating 0-workout weeks as rest/deload context).',
        ),
        'actionableTakeaways': Schema.array(
          items: Schema.string(),
          minItems: 2,
          maxItems: 4,
          description:
              '2 to 4 concise, actionable takeaways for the upcoming week based on weight pace and training progression.',
        ),
      },
    );
  }

  /// Builds the prompt passed to Gemini from [input].
  static String buildPrompt(PaceAssessmentInputEntity input) {
    final isPolish = input.localeCode.toLowerCase().startsWith('pl');
    final languageName = isPolish ? 'Polish (polski)' : 'English';
    final priorWeightWeeksCount = input.priorWeeks
        .where((w) => w.loggedWeightDaysCount > 0 && w.averageWeightKg != null)
        .length;

    final buffer = StringBuffer()
      ..writeln(
        'Output language: $languageName (localeCode: ${input.localeCode})',
      )
      ..writeln(
        'Write all text fields (headlineSummary, weightTrendAnalysis, workoutContextAnalysis, actionableTakeaways) in $languageName.',
      )
      ..writeln()
      ..writeln('## Target & Deterministic Baseline')
      ..writeln(
        '- Target weekly gain range: ${input.gainTarget.minWeeklyGainKg.toStringAsFixed(2)} - ${input.gainTarget.maxWeeklyGainKg.toStringAsFixed(2)} kg/week',
      )
      ..writeln(
        '- Current assessed pace: ${input.currentPaceKgPerWeek.toStringAsFixed(2)} kg/week',
      )
      ..writeln('- Deterministic baselineStatus: ${input.baselineStatus.name}')
      ..writeln('- Prior recorded weight weeks count: $priorWeightWeeksCount')
      ..writeln()
      ..writeln('## Hybrid Classification Guardrail')
      ..writeln(
        'Start from baselineStatus (${input.baselineStatus.name}). Confirm baselineStatus unless the pace is near a threshold boundary and multi-week weight consistency + Hevy exercise progression (best weight x reps and working volume) strongly justify shifting between adjacent statuses (e.g., stagnant vs tooSlow when strength is clearly progressing vs stalled).',
      )
      ..writeln()
      ..writeln('## Assessed Week')
      ..write(_formatWeekSection(input.assessedWeek))
      ..writeln()
      ..writeln('## Prior Weeks (Chronological)');

    for (final week in input.priorWeeks) {
      buffer.write(_formatWeekSection(week));
    }

    return buffer.toString();
  }

  static String _formatWeekSection(AssessedWeekContextEntity week) {
    final buffer = StringBuffer();
    final avgStr = week.averageWeightKg != null
        ? '${week.averageWeightKg!.toStringAsFixed(2)} kg'
        : 'not logged';
    final paceStr = week.paceKgPerWeek != null
        ? '${week.paceKgPerWeek!.toStringAsFixed(2)} kg/week'
        : 'n/a';
    final partialNote = week.isPartialWeek
        ? 'partial week (${week.loggedWeightDaysCount}/7 days logged)'
        : '${week.loggedWeightDaysCount}/7 days logged';

    buffer.writeln(
      '- Week starting ${week.weekStartIso}: avgWeight=$avgStr ($partialNote, isPartialWeek=${week.isPartialWeek}), pace=$paceStr',
    );

    if (week.workoutCount <= 0) {
      buffer.writeln(
        '  Workouts: 0 workouts (rest/deload week; totalWorkingSets=0, totalVolumeKg=0.00 kg)',
      );
    } else {
      buffer.writeln(
        '  Workouts: workoutCount=${week.workoutCount}, totalWorkingSets=${week.totalWorkingSets}, totalVolumeKg=${week.totalVolumeKg.toStringAsFixed(2)} kg',
      );
      for (final ex in week.exercises) {
        final bestSetStr = (ex.bestWeightKg != null || ex.bestReps != null)
            ? '${ex.bestWeightKg?.toStringAsFixed(2) ?? 'bodyweight'} kg × ${ex.bestReps ?? 0} reps'
            : 'n/a';
        buffer.writeln(
          '    * ${ex.title} (${ex.exerciseTemplateId}): bestSet=$bestSetStr, workingSets=${ex.workingSetsCount}, totalVolumeKg=${ex.totalVolumeKg.toStringAsFixed(2)} kg',
        );
      }
    }

    return buffer.toString();
  }

  @override
  Future<PaceAssessmentDto> generateAssessment({
    required PaceAssessmentInputEntity input,
    required DateTime now,
  }) async {
    try {
      final prompt = buildPrompt(input);
      final schema = buildResponseSchema();

      final rawJson = await _generator
          .generateJson(
            prompt: prompt,
            responseSchema: schema,
            systemInstruction: _systemInstruction,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () =>
                throw const ServerException(message: 'AI request timed out'),
          );

      if (rawJson == null || rawJson.trim().isEmpty) {
        throw const ServerException(
          message: 'Empty response from AI pace assessment',
        );
      }

      return _parseAiResponse(rawJson: rawJson, input: input, now: now);
    } on TimeoutException {
      throw const ServerException(message: 'AI request timed out');
    } on FormatException catch (e) {
      throw ServerException(
        message: 'Malformed AI pace assessment response: ${e.message}',
      );
    } on FirebaseAIException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('socketexception') ||
          lower.contains('network') ||
          lower.contains('failed host lookup') ||
          lower.contains('connection')) {
        throw NetworkException(e.message);
      }
      throw ServerException(message: e.message);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw AuthException(e.code, e.message ?? 'Permission denied');
      }
      if (e.code == 'network-error' ||
          e.code == 'network-request-failed' ||
          e.code == 'unavailable' ||
          e.code == 'disconnected') {
        throw NetworkException(e.message ?? 'Network error occurred');
      }
      throw ServerException(message: e.message ?? 'AI service error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      final lower = e.toString().toLowerCase();
      if (e.runtimeType.toString() == 'SocketException' ||
          lower.contains('socketexception') ||
          lower.contains('network') ||
          lower.contains('failed host lookup')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }

  PaceAssessmentDto _parseAiResponse({
    required String rawJson,
    required PaceAssessmentInputEntity input,
    required DateTime now,
  }) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('AI response root must be a JSON object');
    }

    final map = Map<Object?, Object?>.from(decoded);
    final rawStatus = map['status'];
    final resolvedStatus = _resolveHybridStatus(
      rawStatus: rawStatus,
      baselineStatus: input.baselineStatus,
    );

    final headlineSummary = _requireNonEmptyString(map, 'headlineSummary');
    final weightTrendAnalysis = _requireNonEmptyString(
      map,
      'weightTrendAnalysis',
    );
    final workoutContextAnalysis = _requireNonEmptyString(
      map,
      'workoutContextAnalysis',
    );
    final actionableTakeaways = _requireTakeaways(map, 'actionableTakeaways');

    final priorWeightWeeksCount = input.priorWeeks
        .where((w) => w.loggedWeightDaysCount > 0 && w.averageWeightKg != null)
        .length;

    return PaceAssessmentDto(
      status: resolvedStatus.name,
      baselineStatus: input.baselineStatus.name,
      headlineSummary: headlineSummary,
      weightTrendAnalysis: weightTrendAnalysis,
      workoutContextAnalysis: workoutContextAnalysis,
      actionableTakeaways: List.unmodifiable(actionableTakeaways),
      assessedWeekStartIso: input.assessedWeek.weekStartIso,
      isAssessedWeekPartial: input.assessedWeek.isPartialWeek,
      currentPaceKgPerWeek: input.currentPaceKgPerWeek,
      targetMinKgPerWeek: input.gainTarget.minWeeklyGainKg,
      targetMaxKgPerWeek: input.gainTarget.maxWeeklyGainKg,
      priorWeightWeeksCount: priorWeightWeeksCount,
      localeCode: input.localeCode,
      fingerprint: input.fingerprint,
      generatedAt: now.toUtc().toIso8601String(),
    );
  }

  static PaceAssessmentStatus _resolveHybridStatus({
    required Object? rawStatus,
    required PaceAssessmentStatus baselineStatus,
  }) {
    if (rawStatus is String) {
      final trimmed = rawStatus.trim();
      for (final candidate in PaceAssessmentStatus.values) {
        if (candidate.name == trimmed) {
          return candidate;
        }
      }
    }
    return baselineStatus;
  }

  static String _requireNonEmptyString(Map<Object?, Object?> map, String key) {
    final raw = map[key];
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('Missing or empty string field: $key');
    }
    return raw.trim();
  }

  static List<String> _requireTakeaways(Map<Object?, Object?> map, String key) {
    final raw = map[key];
    if (raw is! List) {
      throw FormatException('Field $key must be a list');
    }
    final items = <String>[];
    for (final item in raw) {
      if (item is! String || item.trim().isEmpty) {
        throw FormatException('Items in $key must be non-empty strings');
      }
      items.add(item.trim());
    }
    if (items.length < 2 || items.length > 4) {
      throw FormatException('Field $key must contain between 2 and 4 items');
    }
    return items;
  }
}
