/// Domain entity representing a single daily weight measurement.
class WeightEntryEntity {
  final String dateIso;
  final DateTime date;
  final double weightKg;
  final DateTime updatedAt;

  const WeightEntryEntity({
    required this.dateIso,
    required this.date,
    required this.weightKg,
    required this.updatedAt,
  });

  WeightEntryEntity copyWith({
    String? dateIso,
    DateTime? date,
    double? weightKg,
    DateTime? updatedAt,
  }) {
    return WeightEntryEntity(
      dateIso: dateIso ?? this.dateIso,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightEntryEntity &&
          runtimeType == other.runtimeType &&
          dateIso == other.dateIso &&
          date == other.date &&
          weightKg == other.weightKg &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      dateIso.hashCode ^ date.hashCode ^ weightKg.hashCode ^ updatedAt.hashCode;

  @override
  String toString() =>
      'WeightEntryEntity(dateIso: $dateIso, date: $date, weightKg: $weightKg, updatedAt: $updatedAt)';
}
