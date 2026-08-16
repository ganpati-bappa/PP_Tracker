import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pp_tracker/repositories/firestore/firestore_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two-layer persistence for everything user-specific in the cycle tracker.
///
/// Two data shapes are stored, both as plain JSON maps (the [UserModel] owns
/// the domain <-> map conversion, keeping this store dumb and easily testable):
///
///   • **State doc** — the small, bounded bundle of cycle profile + past-cycle
///     history + preferences. One document.
///   • **Daily logs** — one record per calendar day (mood, flow, symptoms,
///     water, sleep, weight…). Potentially unbounded over time, so stored as
///     one document *per day* rather than a single growing blob.
///
/// Layers, written best-effort and independently:
///   1. **SharedPreferences** — always-on local cache; the sole store for
///      guests and the offline-instant source on launch.
///   2. **Cloud Firestore** — cross-device mirror for signed-in users, under
///      the *private* `users/{uid}` subtree (owner-only per firestore.rules),
///      never on the publicly-readable profile document.
class CycleProfileStore {
  CycleProfileStore({
    required this.useRemote,
    FirebaseFirestore? firestore,
  }) : _db = firestore;

  /// Whether to mirror to Firestore. False for guests and the mock backend.
  final bool useRemote;

  final FirebaseFirestore? _db;
  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  // ---- Keys / paths -------------------------------------------------------

  static String _stateKey(String uid) => 'cycle_state_$uid';
  static String _logsKey(String uid) => 'daily_logs_$uid';

  // Private, owner-only subtree (firestore.rules: users/{uid}/{sub}/{docId}).
  static const String _privateSub = 'private';
  static const String _cycleDoc = 'cycle';
  static const String _logsCollection = 'dailyLogs';

  DocumentReference<Map<String, dynamic>> _stateRef(String uid) =>
      Fs.userRef(_firestore, uid).collection(_privateSub).doc(_cycleDoc);

  CollectionReference<Map<String, dynamic>> _logsRef(String uid) =>
      Fs.userRef(_firestore, uid).collection(_logsCollection);

  // ---- State doc ----------------------------------------------------------

  Future<Map<String, dynamic>?> loadState(String uid) async {
    final local = await _readJson(_stateKey(uid));
    if (local != null) return local;

    if (!useRemote) return null;
    try {
      final snap = await _stateRef(uid).get();
      final data = snap.data();
      if (data == null) return null;
      await _writeJson(_stateKey(uid), data); // warm the cache
      return data;
    } catch (e) {
      debugPrint('CycleProfileStore: remote state load failed: $e');
      return null;
    }
  }

  Future<void> saveState(String uid, Map<String, dynamic> state) async {
    await _writeJson(_stateKey(uid), state);
    if (!useRemote) return;
    try {
      await _stateRef(uid).set(state, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CycleProfileStore: remote state save failed (kept locally): $e');
    }
  }

  // ---- Daily logs ---------------------------------------------------------

  /// Returns all logs keyed by their `yyyy-MM-dd` date string.
  Future<Map<String, Map<String, dynamic>>> loadLogs(String uid) async {
    final localRaw = await _readJson(_logsKey(uid));
    if (localRaw != null && localRaw.isNotEmpty) {
      return localRaw.map(
        (k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()),
      );
    }

    if (!useRemote) return {};
    try {
      final snap = await _logsRef(uid).get();
      final result = <String, Map<String, dynamic>>{
        for (final doc in snap.docs) doc.id: doc.data(),
      };
      if (result.isNotEmpty) {
        await _writeJson(_logsKey(uid), result); // warm the cache
      }
      return result;
    } catch (e) {
      debugPrint('CycleProfileStore: remote logs load failed: $e');
      return {};
    }
  }

  Future<void> saveLog(
      String uid, String dateKey, Map<String, dynamic> log) async {
    final logs = (await _readJson(_logsKey(uid))) ?? {};
    logs[dateKey] = log;
    await _writeJson(_logsKey(uid), logs);
    if (!useRemote) return;
    try {
      await _logsRef(uid).doc(dateKey).set(log, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CycleProfileStore: remote log save failed (kept locally): $e');
    }
  }

  Future<void> deleteLog(String uid, String dateKey) async {
    final logs = await _readJson(_logsKey(uid));
    if (logs != null && logs.remove(dateKey) != null) {
      await _writeJson(_logsKey(uid), logs);
    }
    if (!useRemote) return;
    try {
      await _logsRef(uid).doc(dateKey).delete();
    } catch (e) {
      debugPrint('CycleProfileStore: remote log delete failed: $e');
    }
  }

  // ---- SharedPreferences helpers -----------------------------------------

  Future<Map<String, dynamic>?> _readJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (e) {
      debugPrint('CycleProfileStore: local read failed ($key): $e');
      return null;
    }
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (e) {
      debugPrint('CycleProfileStore: local write failed ($key): $e');
    }
  }
}
