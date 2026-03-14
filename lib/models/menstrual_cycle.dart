import 'dart:math';

enum CyclePhaseType {
  menstrual,
  follicular,
  fertile,
  luteal;

  String toName() => name[0].toUpperCase() + name.substring(1);
}

class CycleDefaults {
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int lutealPhaseLength = 14;
  static const int fertileWindowDays = 6;
}

class CyclePhase {
  final CyclePhaseType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> symptoms;
  final List<String> selfCareTips;

  CyclePhase({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.symptoms,
    required this.selfCareTips,
  });

  int get durationInDays => endDate.difference(startDate).inDays + 1;
}

class CycleDay {
  final Duration date;
  final CyclePhaseType phase;
  final int pregnancyChance; // 0–100%
  final List<String> symptoms;
  final List<String> selfCareTips;
  final List<String> emojis;

  CycleDay({
    required this.date,
    required this.phase,
    required this.pregnancyChance,
    required this.symptoms,
    required this.selfCareTips,
    required this.emojis,
  });

  @override
  String toString() {
    return 'CycleDay(date: $date, phase: $phase, pregnancyChance: $pregnancyChance, symptoms: $symptoms, selfCareTips: $selfCareTips)';
  }
}

class MenstrualCycle {
  final DateTime cycleStartDate;
  final int cycleLength;
  final int periodLength;

  MenstrualCycle({
    required this.cycleStartDate,
    this.cycleLength = CycleDefaults.defaultCycleLength,
    this.periodLength = CycleDefaults.defaultPeriodLength,
  }) {
    if (cycleLength < 21 || cycleLength > 40) {
      throw ArgumentError('cycleLength must be between 21 and 40 days');
    }
    if (periodLength <= 0 || periodLength >= cycleLength) {
      throw ArgumentError('Invalid periodLength');
    }
  }

  // ---------- CORE CYCLE CALCULATION ----------

  DateTime _currentCycleStart(DateTime date) {
    final totalDays = date.difference(cycleStartDate).inDays;

    if (totalDays < 0) {
      throw ArgumentError('Date is before cycle start');
    }

    final cycleOffset = totalDays ~/ cycleLength;
    return cycleStartDate.add(Duration(days: cycleOffset * cycleLength));
  }

  int _cycleDayNumber(DateTime date) {
    final totalDays = date.difference(cycleStartDate).inDays;

    if (totalDays < 0) {
      throw ArgumentError('Date is before cycle start');
    }

    return (totalDays % cycleLength) + 1;
  }

  DateTime get nextCycleStartDate => cycleStartDate.add(Duration(days: cycleLength));

  DateTime get cycleEndDate => cycleStartDate.add(Duration(days: cycleLength - 1));

  /// Fertile day (ovulation day) relative to the cycle of [date]
  DateTime _fertileDateFor(DateTime date) {
    final start = _currentCycleStart(date);
    return start.add(Duration(days: cycleLength - CycleDefaults.lutealPhaseLength));
  }

  // ---------- FERTILITY CALCULATION ----------

  DateTime nextFertileDay({required DateTime fromDate}) {
    final normalizedFrom = DateTime(fromDate.year, fromDate.month, fromDate.day);

    final totalDays = normalizedFrom.difference(cycleStartDate).inDays;

    if (totalDays < 0) {
      return cycleStartDate.add(Duration(days: cycleLength - 14));
    }

    final currentCycleOffset = totalDays % cycleLength;
    final ovulationDayOffset = cycleLength - 14; // zero-based offset

    if (currentCycleOffset <= ovulationDayOffset) {
      // Ovulation is still ahead in this cycle
      final daysUntilOvulation = ovulationDayOffset - currentCycleOffset;

      return normalizedFrom.add(Duration(days: daysUntilOvulation));
    } else {
      // Ovulation already passed, move to next cycle
      final daysUntilNextCycle = cycleLength - currentCycleOffset;

      return normalizedFrom.add(Duration(days: daysUntilNextCycle + ovulationDayOffset));
    }
  }

  int fertilityProbability({required DateTime date}) {
    final day = _cycleDayNumber(date);
    final ovulationDay = cycleLength - CycleDefaults.lutealPhaseLength;

    final distance = (day - ovulationDay).abs();

    if (distance > 5) return 0;

    const probabilities = {0: 35, 1: 30, 2: 20, 3: 10, 4: 5, 5: 2};

    return probabilities[distance] ?? 0;
  }

  int currentPhaseNo(CyclePhaseType phase) => CyclePhaseType.values.indexOf(phase);

  // ---------- DAILY BREAKDOWN ----------

  CycleDay calculateCycleForToday(DateTime today) {
    final duration = today.difference(cycleStartDate);
    final phase = _resolvePhase(today);
    final chance = fertilityProbability(date: today);

    return CycleDay(
      date: duration,
      phase: phase,
      pregnancyChance: chance,
      symptoms: _symptomsForPhase(phase),
      selfCareTips: _selfCareForPhase(phase),
      emojis: symptomsEmojiForPhase(phase),
    );
  }

  // ---------- PHASE RESOLUTION ----------

  CyclePhaseType _resolvePhase(DateTime date) {
    final day = _cycleDayNumber(date);

    final ovulationDay = cycleLength - CycleDefaults.lutealPhaseLength;

    final fertileStart = max(periodLength + 1, ovulationDay - 4);

    final fertileEnd = min(cycleLength, ovulationDay + 1);

    if (day <= periodLength) {
      return CyclePhaseType.menstrual;
    } else if (day < fertileStart) {
      return CyclePhaseType.follicular;
    } else if (day <= fertileEnd) {
      return CyclePhaseType.fertile;
    } else {
      return CyclePhaseType.luteal;
    }
  }

  // ---------- PHASE DURATIONS ----------

  List<int> getPhaseDurations() {
    final ovulationDay = cycleLength - CycleDefaults.lutealPhaseLength;

    final menstrual = periodLength;

    final fertileStart = max(periodLength + 1, ovulationDay - 4);

    final fertileEnd = min(cycleLength, ovulationDay + 1);

    final follicular = max(0, fertileStart - menstrual - 1);

    final fertile = max(0, fertileEnd - fertileStart + 1);

    final luteal = max(0, cycleLength - fertileEnd);

    return [menstrual, follicular, fertile, luteal];
  }

  // ---------- SYMPTOMS & SELF CARE ----------

  List<String> _symptomsForPhase(CyclePhaseType phase) {
    switch (phase) {
      case CyclePhaseType.menstrual:
        return ["Cramps", "Fatigue", "Low mood"];
      case CyclePhaseType.follicular:
        return ["Rising energy", "Mental clarity"];
      case CyclePhaseType.fertile:
        return ["High libido", "Confidence", "Egg-white discharge"];
      case CyclePhaseType.luteal:
        return ["Bloating", "Mood swings", "Cravings"];
    }
  }

  List<String> symptomsEmojiForPhase(CyclePhaseType phase) {
    switch (phase) {
      case CyclePhaseType.menstrual:
        return ["🤕", "😴", "😔"];
      case CyclePhaseType.follicular:
        return ["⚡", "💡"];
      case CyclePhaseType.fertile:
        return ["💕", "✨", "💧"];
      case CyclePhaseType.luteal:
        return ["🎈", "🎭", "🍫"];
    }
  }

  List<String> _selfCareForPhase(CyclePhaseType phase) {
    switch (phase) {
      case CyclePhaseType.menstrual:
        return [
          "Rest more and allow your body time to recover.",
          "Eat warm, comforting foods to ease discomfort.",
          "Practice gentle stretching to relieve tension.",
          "Include iron-rich meals to support your energy.",
        ];
      case CyclePhaseType.follicular:
        return [
          "Start new projects while your energy is rising.",
          "Try light workouts to build momentum.",
          "Eat fresh, nourishing foods to fuel your body.",
        ];
      case CyclePhaseType.fertile:
        return [
          "Join in social activities while you feel confident.",
          "Stay well hydrated throughout the day.",
          "Eat balanced meals to support your body.",
        ];
      case CyclePhaseType.luteal:
        return [
          "Stick to a steady routine to feel grounded.",
          "Reduce caffeine to help with sleep and mood.",
          "Aim to go to bed earlier when you can.",
          "Be kind to yourself and take things gently.",
        ];
    }
  }
}
