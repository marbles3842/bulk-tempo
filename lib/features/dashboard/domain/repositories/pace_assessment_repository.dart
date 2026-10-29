import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';

/// Domain repository boundary for obtaining or refreshing a contextual pace assessment.
abstract class PaceAssessmentRepository {
  /// Returns a cached assessment matching [input.fingerprint] when available,
  /// or generates and caches a fresh AI assessment when missing, outdated, or
  /// [forceRefresh] is `true`.
  Future<Result<PaceAssessmentEntity, AppFailure>> getOrGenerateAssessment({
    required String userId,
    required PaceAssessmentInputEntity input,
    bool forceRefresh = false,
  });
}
