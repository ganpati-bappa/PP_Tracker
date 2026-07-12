import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/services/auth/auth_service.dart';

/// Persistence contract for user profiles (the `users` collection).
///
/// The app talks only to this interface. [FirestoreUserRepository] stores
/// signed-in users in Cloud Firestore; [LocalUserRepository] keeps anonymous
/// "guest" users on-device. Swapping/adding a backend (e.g. a real local DB
/// such as sqflite/Hive behind [LocalUserRepository]) requires no changes in
/// the controllers or UI — this is the seam that makes anonymous users
/// pluggable.
abstract class UserRepository {
  /// One-off read of a stored profile, or null if none exists yet.
  Future<AppUser?> fetchUser(String id);

  /// Live profile updates (counters, edits). Backends without streaming may
  /// emit a single value.
  Stream<AppUser?> watchUser(String id);

  /// Creates the profile on first sign-in, otherwise merges the latest
  /// auth-derived fields (name/email/photo) and refreshes `lastActiveAt`.
  /// Returns the resulting profile.
  Future<AppUser> upsertFromAuth(AuthAccount account);

  /// Persists user-edited profile fields (bio, display name, …).
  Future<void> saveProfile(AppUser user);

  // ---- Activity counters --------------------------------------------------
  // Bumped when the user authors a post/comment or bookmarks an article so the
  // profile stays cheap to render without counting subcollections.
  Future<void> incrementPostCount(String id, [int by = 1]);
  Future<void> incrementCommentCount(String id, [int by = 1]);
  Future<void> incrementBookmarkCount(String id, [int by = 1]);
}
