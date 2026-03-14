import 'package:flutter/material.dart';
import 'package:pp_tracker/components/daily_insights.dart';
import 'package:pp_tracker/components/period_calendar.dart';
import 'package:pp_tracker/components/today_mood.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cycle = MenstrualCycle(
      cycleStartDate: DateTime.now().subtract(const Duration(days: 20)),
      cycleLength: 28,
      periodLength: 5,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Hi, there!',
              style: TextStyle(fontSize: 20, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 5),
            Text('Welcome to have you back', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // Action for info button
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PeriodCalendar(cycle: cycle),
            DailyInsights(cycle: cycle),
            TodayMood(cycle: cycle),
          ],
        ),
      ),
    );
  }
}
