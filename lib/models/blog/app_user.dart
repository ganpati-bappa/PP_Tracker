/// A shared user entity used across the whole app (auth identity, blog author,
/// comment author, profile).
///
/// Pure Dart with no Flutter/Firebase dependency so it can be unit-tested and
/// mapped straight to/from a Firestore document (or a local-DB row for the
/// planned anonymous-user store). Firebase Auth's `User` is the raw auth
/// identity; this is the app-level profile persisted in the `users` collection
/// — hence the `AppUser` name (avoids clashing with `firebase_auth`'s `User`).
class AppUser {
  final String id; // == Firebase Auth uid (or a locally-generated guest id)
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? bio;

  /// How this identity was created: 'google', 'anonymous', 'password', …
  /// Lets the UI and storage layer branch (e.g. anonymous -> local DB).
  final String authProvider;

  /// True for guest identities that are not backed by Firebase Auth. These are
  /// the users the local database will serve once it's plugged in.
  final bool isAnonymous;

  /// Marks verified experts (doctors, dietitians) for the "Expert advice" rail.
  final bool isExpert;

  /// e.g. "OB-GYN", "Registered Dietitian". Shown beside expert names.
  final String? credentials;

  final DateTime joinedAt;

  /// Last time we saw this user active — refreshed on each sign-in.
  final DateTime? lastActiveAt;

  // Activity relationships (authored blogs, likes, bookmarks, comments) are NOT
  // denormalized onto the profile as counters/arrays. They live as their own
  // collections/subcollections and are read by query — `blogs where authorId ==
  // id`, `users/{id}/bookmarks`, `users/{id}/likedBlogs`, `comments where
  // userId == id`. This keeps the profile document small, purely profile data,
  // and free of write-amplification. If a profile ever needs "12 posts" style
  // stats, prefer a Firestore `count()` aggregation over re-introducing
  // counters that must be kept in sync on every write.

  /// Soft-deactivation flag. We never hard-delete a user (it would orphan their
  /// blogs/comments); deactivating hides them and blocks writes while keeping
  /// authored content attributable. Defaults to active for legacy docs.
  final bool isActive;

  /// Free-form bag for forward-compatible backend fields (followers, roles…)
  /// so adding fields later doesn't break deserialization.
  final Map<String, dynamic> metadata;

  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.bio,
    this.authProvider = 'unknown',
    this.isAnonymous = false,
    this.isExpert = false,
    this.credentials,
    required this.joinedAt,
    this.lastActiveAt,
    this.isActive = true,
    this.metadata = const {},
  });

  /// Initials for avatar placeholders, e.g. "Sarah Wilson" -> "SW".
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    String? authProvider,
    bool? isAnonymous,
    bool? isExpert,
    String? credentials,
    DateTime? lastActiveAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      authProvider: authProvider ?? this.authProvider,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isExpert: isExpert ?? this.isExpert,
      credentials: credentials ?? this.credentials,
      joinedAt: joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'authProvider': authProvider,
        'isAnonymous': isAnonymous,
        'isExpert': isExpert,
        'credentials': credentials,
        'joinedAt': joinedAt.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'isActive': isActive,
        'metadata': metadata,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        displayName: map['displayName'] as String? ?? 'Unknown',
        email: map['email'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        bio: map['bio'] as String?,
        authProvider: map['authProvider'] as String? ?? 'unknown',
        isAnonymous: map['isAnonymous'] as bool? ?? false,
        isExpert: map['isExpert'] as bool? ?? false,
        credentials: map['credentials'] as String?,
        joinedAt: DateTime.tryParse(map['joinedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        lastActiveAt: DateTime.tryParse(map['lastActiveAt'] as String? ?? ''),
        isActive: map['isActive'] as bool? ?? true,
        metadata:
            (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  bool operator ==(Object other) => other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
