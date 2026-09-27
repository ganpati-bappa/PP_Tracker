import 'dart:async';

import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/repositories/user_repository.dart';
import 'package:pp_tracker/services/auth/auth_service.dart';

/// On-device [UserRepository] for anonymous "guest" users.
///
/// This is the pluggable local store the app is designed around: today it
/// holds profiles in memory, but because it implements the exact same
/// [UserRepository] surface as [FirestoreUserRepository], swapping the backing
/// [_store] for a real local database (sqflite, Hive, Isar, shared_preferences,
/// …) is a self-contained change — nothing in the controllers or UI needs to
/// know. Wire it up by:
///   1. replacing the in-memory [_store] map with your DB's read/write calls;
///   2. serializing via [AppUser.toMap] / [AppUser.fromMap] (already pure-Dart).
class LocalUserRepository implements UserRepository {
  final Map<String, AppUser> _store = {};
  final StreamController<AppUser?> _changes =
      StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> fetchUser(String id) async => _store[id];

  @override
  Stream<AppUser?> watchUser(String id) async* {
    yield _store[id];
    yield* _changes.stream.where((u) => u?.id == id);
  }

  @override
  Future<AppUser> upsertFromAuth(AuthAccount account) async {
    final now = DateTime.now();
    final existing = _store[account.uid];
    final user = (existing ??
            AppUser(
              id: account.uid,
              displayName: account.displayName?.trim().isNotEmpty == true
                  ? account.displayName!
                  : 'Guest',
              joinedAt: now,
              authProvider: 'anonymous',
              isAnonymous: true,
            ))
        .copyWith(
      email: account.email,
      avatarUrl: account.photoUrl,
      lastActiveAt: now,
    );
    return _save(user);
  }

  @override
  Future<void> saveProfile(AppUser user) async {
    final existing = _store[user.id];
    if (existing == null) {
      _save(user);
      return;
    }
    _save(existing.copyWith(
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
      credentials: user.credentials,
      isExpert: user.isExpert,
      metadata: user.metadata,
    ));
  }

  @override
  Future<void> setActive(String id, bool active) async {
    final u = _store[id];
    if (u != null) _save(u.copyWith(isActive: active));
  }

  AppUser _save(AppUser user) {
    _store[user.id] = user;
    _changes.add(user);
    return user;
  }

  void dispose() => _changes.close();
}
