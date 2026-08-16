import 'package:flutter_test/flutter_test.dart';
import 'package:pp_tracker/models/daily_log.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:pp_tracker/repositories/cycle_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyLog serialization', () {
    test('round-trips every field including enums and sets', () {
      final log = DailyLog(
        date: DateTime(2026, 8, 16),
        symptoms: {Symptom.cramps, Symptom.fatigue},
        mood: Mood.calm,
        flow: FlowIntensity.heavy,
        energy: 4,
        waterMl: 1500,
        sleepHours: 7.5,
        weightKg: 61.2,
        temperatureC: 36.7,
        medications: const ['Iron'],
        notes: 'ok',
        intimacy: true,
      );
      final restored = DailyLog.fromMap(log.toMap());
      expect(restored.date, DateTime(2026, 8, 16));
      expect(restored.symptoms, {Symptom.cramps, Symptom.fatigue});
      expect(restored.mood, Mood.calm);
      expect(restored.flow, FlowIntensity.heavy);
      expect(restored.energy, 4);
      expect(restored.waterMl, 1500);
      expect(restored.sleepHours, 7.5);
      expect(restored.weightKg, 61.2);
      expect(restored.temperatureC, 36.7);
      expect(restored.medications, const ['Iron']);
      expect(restored.notes, 'ok');
      expect(restored.intimacy, true);
    });

    test('tolerates unknown enum names and missing fields', () {
      final restored = DailyLog.fromMap({
        'date': DateTime(2026, 1, 1).toIso8601String(),
        'symptoms': ['cramps', 'not_a_symptom'],
        'mood': 'not_a_mood',
      });
      expect(restored.symptoms, {Symptom.cramps}); // unknown dropped
      expect(restored.mood, isNull);
      expect(restored.flow, FlowIntensity.none);
      expect(restored.waterMl, 0);
    });
  });

  test('CycleRecord round-trips', () {
    final rec = CycleRecord(
        startDate: DateTime(2026, 3, 10), cycleLength: 29, periodLength: 5);
    final restored = CycleRecord.fromMap(rec.toMap());
    expect(restored.cycleLength, 29);
    expect(restored.periodLength, 5);
    expect(restored.startDate, DateTime(2026, 3, 10));
  });

  group('CycleProfileStore (offline / SharedPreferences layer)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('state doc saves and loads without a network', () async {
      final store = CycleProfileStore(useRemote: false);
      const uid = 'u1';
      await store.saveState(uid, {
        'lastPeriodStart': DateTime(2026, 8, 1).toIso8601String(),
        'cycleLength': 30,
        'periodLength': 6,
        'history': [],
        'preferences': {'name': 'Ajay', 'goal': 'conceive'},
      });
      final loaded = await store.loadState(uid);
      expect(loaded, isNotNull);
      expect(loaded!['cycleLength'], 30);
      expect((loaded['preferences'] as Map)['name'], 'Ajay');
    });

    test('daily logs save, load and delete locally', () async {
      final store = CycleProfileStore(useRemote: false);
      const uid = 'u1';
      await store.saveLog(uid, '2026-08-16', {'mood': 'happy', 'waterMl': 500});
      await store.saveLog(uid, '2026-08-17', {'mood': 'calm', 'waterMl': 800});

      var logs = await store.loadLogs(uid);
      expect(logs.length, 2);
      expect(logs['2026-08-16']!['mood'], 'happy');

      await store.deleteLog(uid, '2026-08-16');
      logs = await store.loadLogs(uid);
      expect(logs.length, 1);
      expect(logs.containsKey('2026-08-16'), isFalse);
    });

    test('data is scoped per uid', () async {
      final store = CycleProfileStore(useRemote: false);
      await store.saveLog('a', '2026-08-16', {'mood': 'happy'});
      final other = await store.loadLogs('b');
      expect(other, isEmpty);
    });
  });
}
