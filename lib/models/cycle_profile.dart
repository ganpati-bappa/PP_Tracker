import 'package:pp_tracker/models/menstrual_cycle.dart';

/// The three metrics collected during onboarding that are enough to bootstrap
/// the whole [MenstrualCycle] engine:
///
///   • [lastPeriodStart] — the first day of the user's most recent period
///   • [cycleLength]     — average days from one period start to the next
///   • [periodLength]    — average days of bleeding
///
/// Everything the app predicts (phases, fertile window, next period,
/// ovulation) is derived from these. Kept as a small, pure-Dart, serializable
/// value object so it can be cached in SharedPreferences and mirrored to
/// Firestore without dragging in Flutter/Firebase types.
class CycleProfile {
  final DateTime lastPeriodStart;
  final int cycleLength;
  final int periodLength;

  /// When this profile was last edited — lets a future sync layer resolve
  /// "which copy wins" between the local cache and the cloud.
  final DateTime updatedAt;

  CycleProfile({
    required DateTime lastPeriodStart,
    required int cycleLength,
    required int periodLength,
    DateTime? updatedAt,
  })  : lastPeriodStart = _dateOnly(lastPeriodStart),
        cycleLength = cycleLength.clamp(minCycleLength, maxCycleLength),
        periodLength = periodLength.clamp(minPeriodLength, maxPeriodLength),
        updatedAt = updatedAt ?? DateTime.now();

  // ---- Shared, single-source-of-truth input ranges ------------------------
  // Reused by the onboarding form and [UserModel.updateCycleSettings] so the
  // clamps can never drift apart.
  static const int minCycleLength = 21;
  static const int maxCycleLength = 40;
  static const int minPeriodLength = 2;
  static const int maxPeriodLength = 10;

  /// A friendly, medically-typical default so onboarding is one tap away from
  /// done: today as the last period start, a 28-day cycle, 5 days of bleeding.
  factory CycleProfile.defaults() => CycleProfile(
        lastPeriodStart: DateTime.now(),
        cycleLength: MenstrualCycle.defaultCycleLength,
        periodLength: MenstrualCycle.defaultPeriodLength,
      );

  CycleProfile copyWith({
    DateTime? lastPeriodStart,
    int? cycleLength,
    int? periodLength,
    DateTime? updatedAt,
  }) =>
      CycleProfile(
        lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
        cycleLength: cycleLength ?? this.cycleLength,
        periodLength: periodLength ?? this.periodLength,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'lastPeriodStart': lastPeriodStart.toIso8601String(),
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Tolerant of missing/garbled fields — falls back to sensible defaults so a
  /// half-written cache or a schema change never crashes hydration.
  factory CycleProfile.fromMap(Map<String, dynamic> map) => CycleProfile(
        lastPeriodStart:
            DateTime.tryParse(map['lastPeriodStart'] as String? ?? '') ??
                DateTime.now(),
        cycleLength: (map['cycleLength'] as num?)?.toInt() ??
            MenstrualCycle.defaultCycleLength,
        periodLength: (map['periodLength'] as num?)?.toInt() ??
            MenstrualCycle.defaultPeriodLength,
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      );

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  bool operator ==(Object other) =>
      other is CycleProfile &&
      other.lastPeriodStart == lastPeriodStart &&
      other.cycleLength == cycleLength &&
      other.periodLength == periodLength;

  @override
  int get hashCode =>
      Object.hash(lastPeriodStart, cycleLength, periodLength);
}
