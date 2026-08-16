import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/repositories/user_repository.dart';
import 'package:pp_tracker/services/auth/auth_service.dart';

/// Cloud Firestore implementation of [UserRepository].
///
/// Profiles live in the top-level `users` collection, keyed by the Firebase
/// Auth uid. `joinedAt` / `lastActiveAt` are stored as native Firestore
/// [Timestamp]s (idiomatic + queryable) and converted to/from ISO strings at
/// this boundary so [AppUser] can stay a pure-Dart, backend-agnostic model.
///
/// A user's posts and comments live in their own collections
/// (`blogs` where `authorId == uid`, `comments` where `userId == uid`); the
/// counters on the profile doc are the cheap, denormalized rollups of those.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Future<AppUser?> fetchUser(String id) async {
    final snap = await _users.doc(id).get();
    return _fromSnap(snap);
  }

  @override
  Stream<AppUser?> watchUser(String id) =>
      _users.doc(id).snapshots().map(_fromSnap);

  @override
  Future<AppUser> upsertFromAuth(AuthAccount account) async {
    final ref = _users.doc(account.uid);
    final existing = await ref.get();

    if (existing.exists) {
      // Refresh the fields that can change on the identity provider, but never
      // clobber user-edited fields (bio, credentials) or the counters.
      await ref.set({
        if (account.displayName != null) 'displayName': account.displayName,
        'email': account.email,
        'avatarUrl': account.photoUrl,
        'authProvider': account.provider,
        'isAnonymous': account.isAnonymous,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      final now = FieldValue.serverTimestamp();
      await ref.set({
        'id': account.uid,
        'displayName': account.displayName?.trim().isNotEmpty == true
            ? account.displayName
            : (account.email?.split('@').first ?? 'Friend'),
        'email': account.email,
        'avatarUrl': account.photoUrl,
        'bio': null,
        'authProvider': account.provider,
        'isAnonymous': account.isAnonymous,
        'isExpert': false,
        'credentials': null,
        'joinedAt': now,
        'lastActiveAt': now,
        'isActive': true,
        'metadata': <String, dynamic>{},
      });
    }

    final saved = await ref.get();
    return _fromSnap(saved)!;
  }

  @override
  Future<void> saveProfile(AppUser user) async {
    // Only user-owned profile fields; auth/counters are managed elsewhere.
    await _users.doc(user.id).set({
      'displayName': user.displayName,
      'bio': user.bio,
      'avatarUrl': user.avatarUrl,
      'credentials': user.credentials,
      'isExpert': user.isExpert,
      'metadata': user.metadata,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setActive(String id, bool active) => _users.doc(id).set(
        {
          'isActive': active,
          'deactivatedAt':
              active ? FieldValue.delete() : FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  AppUser? _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return null;
    // Normalize Firestore Timestamps to the ISO strings AppUser.fromMap wants.
    return AppUser.fromMap({
      ...data,
      'id': data['id'] ?? snap.id,
      'joinedAt': _isoOrNull(data['joinedAt']),
      'lastActiveAt': _isoOrNull(data['lastActiveAt']),
    });
  }

  String? _isoOrNull(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return null;
  }
}
