import 'package:flutter/cupertino.dart';
import 'package:pp_tracker/components/base_card.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';

class TodayMood extends StatelessWidget {
  final MenstrualCycle cycle;

  const TodayMood({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final cycleDay = cycle.calculateCycleForToday(DateTime.now());
    final symptoms = cycleDay.symptoms ?? [];
    final emojis = cycleDay.emojis ?? [];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text('Today\'s Mood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: false,
              itemCount: symptoms.length,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                  margin: EdgeInsets.only(right: 8, top: 16, bottom: 15),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: RichText(
                        text: TextSpan(
                          text: emojis[index],
                          style: const TextStyle(fontSize: 20),
                          children: [
                            TextSpan(
                              text: '  ${symptoms[index]}',
                              style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
