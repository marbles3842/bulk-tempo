import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';

part 'pace_assessment_dto.freezed.dart';
part 'pace_assessment_dto.g.dart';

/// Data Transfer Object for serializing and deserializing contextual pace
/// assessments between Firebase Realtime Database and [PaceAssessmentEntity].
@Freezed(toJson: true)
abstract class PaceAssessmentDto with _$PaceAssessmentDto {
  const PaceAssessmentDto._();

  const factory PaceAssessmentDto({
    required String status,
    required String baselineStatus,
    required String headlineSummary,
    required String weightTrendAnalysis,
    required String workoutContextAnalysis,
    required List<String> actionableTakeaways,
    required String assessedWeekStartIso,
    required bool isAssessedWeekPartial,
    required double currentPaceKgPerWeek,
    required double targetMinKgPerWeek,
    required double targetMaxKgPerWeek,
    required int priorWeightWeeksCount,
    required String localeCode,
    required String fingerprint,
    required String generatedAt,
  }) = _PaceAssessmentDto;

  /// Deserializes and validates a Firebase Realtime Database map.
  ///
  /// Throws a [FormatException] if any required field is missing or malformed.
  factory PaceAssessmentDto.fromRtdbMap(Map<Object?, Object?> map) {
    final statusStr = _requireNonEmptyString(map, 'status');
    final baselineStatusStr = _requireNonEmptyString(map, 'baselineStatus');
    _parseStatusOrThrow(statusStr, 'status');
    _parseStatusOrThrow(baselineStatusStr, 'baselineStatus');

    final headlineSummary = _requireNonEmptyString(map, 'headlineSummary');
    final weightTrendAnalysis = _requireNonEmptyString(
      map,
      'weightTrendAnalysis',
    );
    final workoutContextAnalysis = _requireNonEmptyString(
      map,
      'workoutContextAnalysis',
    );
    final actionableTakeaways = _requireStringList(map, 'actionableTakeaways');

    final assessedWeekStartIso = _requireNonEmptyString(
      map,
      'assessedWeekStartIso',
    );
    if (WeekDateUtils.tryParseIsoDate(assessedWeekStartIso) == null) {
      throw const FormatException('Invalid assessedWeekStartIso date');
    }

    final isAssessedWeekPartial = _requireBool(map, 'isAssessedWeekPartial');
    final currentPaceKgPerWeek = _requireFiniteDouble(
      map,
      'currentPaceKgPerWeek',
    );
    final targetMinKgPerWeek = _requireFiniteDouble(map, 'targetMinKgPerWeek');
    final targetMaxKgPerWeek = _requireFiniteDouble(map, 'targetMaxKgPerWeek');
    if (targetMinKgPerWeek <= 0 || targetMaxKgPerWeek <= targetMinKgPerWeek) {
      throw const FormatException('Invalid target gain range in cached DTO');
    }

    final priorWeightWeeksCount = _requireInt(map, 'priorWeightWeeksCount');
    if (priorWeightWeeksCount < 2) {
      throw const FormatException(
        'priorWeightWeeksCount must be at least 2 in cached DTO',
      );
    }

    final localeCode = _requireNonEmptyString(map, 'localeCode');
    final fingerprint = _requireNonEmptyString(map, 'fingerprint');
    final generatedAt = _requireNonEmptyString(map, 'generatedAt');
    if (DateTime.tryParse(generatedAt) == null) {
      throw const FormatException('Invalid generatedAt ISO-8601 timestamp');
    }

    return PaceAssessmentDto(
      status: statusStr,
      baselineStatus: baselineStatusStr,
      headlineSummary: headlineSummary,
      weightTrendAnalysis: weightTrendAnalysis,
      workoutContextAnalysis: workoutContextAnalysis,
      actionableTakeaways: List.unmodifiable(actionableTakeaways),
      assessedWeekStartIso: assessedWeekStartIso,
      isAssessedWeekPartial: isAssessedWeekPartial,
      currentPaceKgPerWeek: currentPaceKgPerWeek,
      targetMinKgPerWeek: targetMinKgPerWeek,
      targetMaxKgPerWeek: targetMaxKgPerWeek,
      priorWeightWeeksCount: priorWeightWeeksCount,
      localeCode: localeCode,
      fingerprint: fingerprint,
      generatedAt: generatedAt,
    );
  }

  /// Creates a DTO from a [PaceAssessmentEntity].
  factory PaceAssessmentDto.fromEntity(PaceAssessmentEntity entity) {
    return PaceAssessmentDto(
      status: entity.status.name,
      baselineStatus: entity.baselineStatus.name,
      headlineSummary: entity.headlineSummary,
      weightTrendAnalysis: entity.weightTrendAnalysis,
      workoutContextAnalysis: entity.workoutContextAnalysis,
      actionableTakeaways: List.unmodifiable(entity.actionableTakeaways),
      assessedWeekStartIso: entity.assessedWeekStartIso,
      isAssessedWeekPartial: entity.isAssessedWeekPartial,
      currentPaceKgPerWeek: entity.currentPaceKgPerWeek,
      targetMinKgPerWeek: entity.targetMinKgPerWeek,
      targetMaxKgPerWeek: entity.targetMaxKgPerWeek,
      priorWeightWeeksCount: entity.priorWeightWeeksCount,
      localeCode: entity.localeCode,
      fingerprint: entity.fingerprint,
      generatedAt: entity.generatedAt.toUtc().toIso8601String(),
    );
  }

  /// Converts this DTO to a [PaceAssessmentEntity].
  PaceAssessmentEntity toEntity() {
    final parsedStatus = _parseStatusOrThrow(status, 'status');
    final parsedBaselineStatus = _parseStatusOrThrow(
      baselineStatus,
      'baselineStatus',
    );
    final parsedGeneratedAt = DateTime.tryParse(generatedAt)?.toUtc();
    if (parsedGeneratedAt == null) {
      throw const FormatException('Invalid generatedAt timestamp');
    }

    return PaceAssessmentEntity(
      status: parsedStatus,
      baselineStatus: parsedBaselineStatus,
      headlineSummary: headlineSummary,
      weightTrendAnalysis: weightTrendAnalysis,
      workoutContextAnalysis: workoutContextAnalysis,
      actionableTakeaways: List.unmodifiable(actionableTakeaways),
      assessedWeekStartIso: assessedWeekStartIso,
      isAssessedWeekPartial: isAssessedWeekPartial,
      currentPaceKgPerWeek: currentPaceKgPerWeek,
      targetMinKgPerWeek: targetMinKgPerWeek,
      targetMaxKgPerWeek: targetMaxKgPerWeek,
      priorWeightWeeksCount: priorWeightWeeksCount,
      localeCode: localeCode,
      fingerprint: fingerprint,
      generatedAt: parsedGeneratedAt,
    );
  }

  static String _requireNonEmptyString(Map<Object?, Object?> map, String key) {
    final raw = map[key];
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('Missing or empty string field: $key');
    }
    return raw.trim();
  }

  static bool _requireBool(Map<Object?, Object?> map, String key) {
    final raw = map[key];
    if (raw is! bool) {
      throw FormatException('Field $key must be a boolean');
    }
    return raw;
  }

  static double _requireFiniteDouble(Map<Object?, Object?> map, String key) {
    final raw = map[key];
    if (raw is! num) {
      throw FormatException('Field $key must be numeric');
    }
    final value = raw.toDouble();
    if (!value.isFinite) {
      throw FormatException('Field $key must be finite');
    }
    return value;
  }

  static int _requireInt(Map<Object?, Object?> map, String key) {
    final raw = map[key];
    if (raw is int) {
      return raw;
    }
    if (raw is num && raw == raw.toInt()) {
      return raw.toInt();
    }
    throw FormatException('Field $key must be an integer');
  }

  static List<String> _requireStringList(
    Map<Object?, Object?> map,
    String key,
  ) {
    final raw = map[key];
    if (raw is! List || raw.isEmpty) {
      throw FormatException('Field $key must be a non-empty list');
    }
    final result = <String>[];
    for (final item in raw) {
      if (item is! String || item.trim().isEmpty) {
        throw FormatException('Items in $key must be non-empty strings');
      }
      result.add(item.trim());
    }
    return result;
  }

  static PaceAssessmentStatus _parseStatusOrThrow(
    String value,
    String fieldName,
  ) {
    for (final candidate in PaceAssessmentStatus.values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
    throw FormatException('Invalid $fieldName enum value: $value');
  }
}
