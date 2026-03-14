import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:pp_tracker/components/base_card.dart' as base_card;

class DailyInsights extends StatelessWidget {
  final MenstrualCycle cycle;
  const DailyInsights({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text('Daily Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getPregnancyChanceWidget(cycle),
                _getNextPeriodStart(cycle),
                _getNextOvulationDay(cycle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _getNextPeriodStart(MenstrualCycle cycle) {
  final nextPeriod = cycle.nextCycleStartDate;
  final daysUntil = nextPeriod.difference(DateTime.now()).inDays;
  return base_card.Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
    child: Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              text: 'Next Period ',
              style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
              children: [
                TextSpan(text: '\n'),
                TextSpan(
                  text: '  Starts In',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemPink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$daysUntil',
                style: const TextStyle(fontSize: 26, color: CupertinoColors.systemCyan),
              ),
              const Text('days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _getNextOvulationDay(MenstrualCycle cycle) {
  final DateTime nextOvulation = cycle.nextFertileDay(
    fromDate: DateTime.now(),
  ); // Handle past ovulation in current cycle
  final daysUntil = nextOvulation.difference(DateTime.now()).inDays;
  return base_card.Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    child: Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              text: 'Next Ovulation Day',
              style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
              children: [
                TextSpan(text: '\n'),
                TextSpan(
                  text: 'Comes In',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemPink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$daysUntil',
                style: const TextStyle(fontSize: 26, color: CupertinoColors.systemGreen),
              ),
              const Text('days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _getPregnancyChanceWidget(MenstrualCycle cycle) {
  final chance = cycle.fertilityProbability(date: DateTime.now());
  FertilityLevel level = getFertilityLevel(chance);
  return base_card.Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Container(
      height: 140,
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              text: 'Pregnancy ',
              style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
              children: [
                TextSpan(text: '\n'),
                TextSpan(
                  text: '  Chance',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemPink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(125, 125),
                painter: CirclePainter(chance: chance),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(level.emoji, style: TextStyle(fontSize: 26)),
                  Text(
                    level.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class CirclePainter extends CustomPainter {
  final double strokeWidth;
  final int chance;

  const CirclePainter({this.strokeWidth = 8, required this.chance});

  @override
  void paint(Canvas canvas, Size size) {
    FertilityLevel level = getFertilityLevel(chance);
    final paint = Paint()
      ..color = level.color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final shadowPaint = Paint()
      ..color = level.color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 8)
      ..color = (level == FertilityLevel.safe)
          ? level.color
          : const Color.fromARGB(60, 100, 100, 100);

    if (level == FertilityLevel.safe) {
      canvas.drawArc(
        Rect.fromLTWH(5, 10, size.width - 20, size.height - 20),
        0,
        pi * 2,
        false,
        shadowPaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromLTWH(5, 14, size.width - 20, size.height - 20),
        pi / 2,
        -pi * 2 * (chance / 100),
        false,
        shadowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromLTWH(5, 10, size.width - 20, size.height - 20),
      0,
      pi * 2,
      false,
      outer,
    );

    canvas.drawArc(
      Rect.fromLTWH(5, 10, size.width - 20, size.height - 20),
      pi / 2,
      -pi * 2 * (chance / 100),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

FertilityLevel getFertilityLevel(int chance) {
  if (chance == 0) return FertilityLevel.safe;
  if (chance < 5) return FertilityLevel.low;
  if (chance < 20) return FertilityLevel.medium;
  if (chance < 30) return FertilityLevel.high;
  return FertilityLevel.veryHigh;
}

enum FertilityLevel {
  safe,
  low,
  medium,
  high,
  veryHigh;

  String get label {
    if (this == FertilityLevel.safe) return 'Safe Day';
    if (this == FertilityLevel.low) return 'Low ';
    if (this == FertilityLevel.medium) return 'Medium';
    if (this == FertilityLevel.high) return 'High ';
    return 'Very High';
  }

  String get emoji {
    if (this == FertilityLevel.safe) return '☘️';
    if (this == FertilityLevel.low) return '🪫';
    if (this == FertilityLevel.medium) return '⚠️';
    if (this == FertilityLevel.high) return '🚨';
    return '🔥';
  }

  Color get color {
    if (this == FertilityLevel.safe) return const Color.fromRGBO(159, 254, 124, 1);
    if (this == FertilityLevel.low) return const Color.fromARGB(255, 200, 200, 200);
    if (this == FertilityLevel.medium) return const Color.fromRGBO(254, 200, 120, 1);
    if (this == FertilityLevel.high) return const Color.fromRGBO(254, 144, 169, 1);
    return const Color.fromARGB(255, 255, 93, 104);
  }
}
