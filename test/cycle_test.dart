import 'package:flutter_test/flutter_test.dart';
import 'package:pp_tracker/models/cycle_phase.dart';
import 'package:pp_tracker/models/cycle_profile.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime _daysAgo(int d) {
  final t = _today();
  return DateTime(t.year, t.month, t.day - d);
}

void main() {
  group('CycleProfile', () {
    test('round-trips through toMap/fromMap', () {
      final profile = CycleProfile(
        lastPeriodStart: DateTime(2026, 8, 1),
        cycleLength: 30,
        periodLength: 6,
      );
      final restored = CycleProfile.fromMap(profile.toMap());
      expect(restored.lastPeriodStart, profile.lastPeriodStart);
      expect(restored.cycleLength, 30);
      expect(restored.periodLength, 6);
      expect(restored, profile);
    });

    test('clamps out-of-range values to the shared limits', () {
      final tooBig =
          CycleProfile(lastPeriodStart: _today(), cycleLength: 99, periodLength: 40);
      expect(tooBig.cycleLength, CycleProfile.maxCycleLength);
      expect(tooBig.periodLength, CycleProfile.maxPeriodLength);

      final tooSmall =
          CycleProfile(lastPeriodStart: _today(), cycleLength: 1, periodLength: 0);
      expect(tooSmall.cycleLength, CycleProfile.minCycleLength);
      expect(tooSmall.periodLength, CycleProfile.minPeriodLength);
    });

    test('fromMap tolerates missing fields with defaults', () {
      final p = CycleProfile.fromMap(const {});
      expect(p.cycleLength, MenstrualCycle.defaultCycleLength);
      expect(p.periodLength, MenstrualCycle.defaultPeriodLength);
    });
  });

  group('MenstrualCycle predictions', () {
    test('period starting today is cycle day 1, menstrual phase', () {
      final cycle = MenstrualCycle(
        cycleStartDate: _today(),
        cycleLength: 28,
        periodLength: 5,
      );
      expect(cycle.currentCycleDay, 1);
      expect(cycle.currentPhase, CyclePhase.menstrual);
      expect(cycle.daysUntilNextPeriod, 28);
    });

    test('cycle day counts up correctly within a cycle', () {
      final cycle = MenstrualCycle(
        cycleStartDate: _daysAgo(10),
        cycleLength: 28,
        periodLength: 5,
      );
      expect(cycle.currentCycleDay, 11);
      // Day 11 of a 28-day cycle: past bleeding, inside the fertile/ovulation
      // window (ovulation day == 14).
      expect(cycle.daysUntilNextPeriod, 18);
    });

    test('anchor from a previous cycle re-projects to the current cycle', () {
      // Last logged period was 35 days ago on a 28-day cycle: the engine should
      // roll forward to the current cycle (day 7), not report day 36.
      final cycle = MenstrualCycle(
        cycleStartDate: _daysAgo(35),
        cycleLength: 28,
        periodLength: 5,
      );
      expect(cycle.currentCycleDay, 8); // 35 - 28 = 7 days in => day 8
      expect(cycle.currentCycleDay, lessThanOrEqualTo(28));
    });

    test('ovulation and next period land on the expected days', () {
      final start = _today();
      final cycle = MenstrualCycle(
        cycleStartDate: start,
        cycleLength: 28,
        periodLength: 5,
      );
      // ovulationDayOfCycle == cycleLength - lutealPhaseLength == 14 (1-based)
      expect(
        cycle.ovulationDate,
        DateTime(start.year, start.month, start.day + 13),
      );
      expect(
        cycle.nextPeriodDate,
        DateTime(start.year, start.month, start.day + 28),
      );
    });
  });
}
