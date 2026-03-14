import 'package:flutter/material.dart';
import 'package:pp_tracker/components/base_card.dart' as base_card;
import 'package:pp_tracker/components/multi_colour_semi_circle.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:flutter/cupertino.dart';

class PeriodCalendar extends StatelessWidget {
  final MenstrualCycle cycle;
  const PeriodCalendar({super.key, required this.cycle});

  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return base_card.Card(
      child: Container(
        alignment: Alignment.center,
        child: Column(
          children: [_buildCalendarHeader(), _buildPhaseProgressor(), _buildSelfCareWidget()],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final now = DateTime.now();
    final weekDays = [];
    final todayDay = now.day;
    for (int day = -3; day <= 3; day++) {
      final date = now.add(Duration(days: day));
      weekDays.add({'day': date.day.toString(), 'weekday': PeriodCalendar.days[date.weekday - 1]});
    }
    return SizedBox(
      height: 100,
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: int.parse(day['day']) == todayDay
                    ? const Color.fromARGB(255, 255, 228, 244)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: int.parse(day['day']) == todayDay
                    ? Border.all(color: const Color.fromARGB(255, 255, 180, 180), width: 2)
                    : null,
              ),
              child: Column(
                spacing: 2,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['day'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.systemPink,
                    ),
                  ),
                  Text(
                    day['weekday'],
                    style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 128, 128, 128)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhaseProgressor() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      height: 200,
      child: MultiColourSemiCircleDart(size: 3840, strokeWidth: 10, cycle: cycle),
    );
  }

  Widget _buildSelfCareWidget() {
    DateTime now = DateTime.now();
    final selfCare = cycle.calculateCycleForToday(now).selfCareTips;
    int randomIndex = now.day % selfCare.length;
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(bottom: 16, top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Color.fromRGBO(254, 144, 169, 1), Color.fromARGB(255, 254, 249, 223)],
        ),
      ),
      child: Text(selfCare[randomIndex]),
    );
  }
}
