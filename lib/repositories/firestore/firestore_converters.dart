import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/comment.dart';
import 'package:pp_tracker/repositories/firestore/firestore_paths.dart';

/// The boundary that converts between the pure-Dart domain models
/// (`Blog`, `Comment`, `AppUser` — none of which import `cloud_firestore`) and
/// the raw Firestore document shape.
///
/// Two concerns live here so they can't drift apart:
///  1. **Type fidelity** — dates are stored as native [Timestamp]s (queryable,
///     idiomatic) and the author edge as a real [DocumentReference], while the
///     models keep using ISO strings / ids so they stay backend-agnostic and
///     unit-testable.
///  2. **Forward/back compatibility** — reads go through the models'
///     `fromMap`, which already defaults every missing/nullable field, so old
///     documents written before a field existed deserialize safely and new
///     fields on new documents are ignored by old clients.
class FirestoreConverters {
  FirestoreConverters._();

  // ---------------------------------------------------------------------------
  // Blog
  // ---------------------------------------------------------------------------

  /// Serializes a [Blog] for storage. [isCreate] initializes immutable-on-write
  /// fields (`createdAt`) and the denormalized counters; on update we leave the
  /// server-owned counters untouched (see [FirestoreBlogRepository.upsertBlog]).
  static Map<String, dynamic> blogToFirestore(
    Blog blog,
    FirebaseFirestore db, {
    required bool isCreate,
  }) {
    final map = blog.toMap()
      // Replace ISO strings with native Timestamps.
      ..['publishedAt'] = _tsFromIso(blog.publishedAt)
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['lastVerifiedAt'] = _tsOrNull(blog.lastVerifiedAt)
      // A real reference to the author document (in addition to the
      // denormalized author* fields used for cheap rendering).
      ..['authorRef'] = Fs.userRef(db, blog.authorId)
      // Lower-cased / tokenized fields powering the search layer.
      ..['titleLower'] = blog.title.toLowerCase().trim()
      ..['authorNameLower'] = blog.authorName.toLowerCase().trim()
      ..['keywords'] = buildKeywords(blog)
      // Denormalized, orderable ranking signal for the "trending" feed.
      ..['engagementScore'] = blog.engagementScore
      ..['isDeleted'] = false;

    if (isCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    } else {
      // Never let a possibly-stale in-memory model clobber server counters.
      map.remove('likeCount');
      map.remove('commentCount');
      map.remove('viewCount');
      map.remove('engagementScore');
      map.remove('createdAt');
    }
    return map;
  }

  static Blog blogFromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    return Blog.fromMap({
      ...data,
      'id': snap.id,
      'publishedAt': _isoOrNull(data['publishedAt']),
      'updatedAt': _isoOrNull(data['updatedAt']),
      'lastVerifiedAt': _isoOrNull(data['lastVerifiedAt']),
    });
  }

  // ---------------------------------------------------------------------------
  // Comment
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> commentToFirestore(
    Comment comment,
    FirebaseFirestore db,
  ) {
    return comment.toMap()
      ..['createdAt'] = _tsFromIso(comment.createdAt)
      ..['updatedAt'] = _tsFromIso(comment.updatedAt)
      ..['blogRef'] = Fs.blogRef(db, comment.blogId)
      ..['authorRef'] = Fs.userRef(db, comment.userId);
  }

  static Comment commentFromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    return Comment.fromMap({
      ...data,
      'id': snap.id,
      'createdAt': _isoOrNull(data['createdAt']),
      'updatedAt': _isoOrNull(data['updatedAt']),
    });
  }

  // ---------------------------------------------------------------------------
  // AppUser (read side — the write side lives in FirestoreUserRepository)
  // ---------------------------------------------------------------------------

  static AppUser? appUserFromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return null;
    return AppUser.fromMap({
      ...data,
      'id': data['id'] ?? snap.id,
      'joinedAt': _isoOrNull(data['joinedAt']),
      'lastActiveAt': _isoOrNull(data['lastActiveAt']),
    });
  }

  // ---------------------------------------------------------------------------
  // Search index
  // ---------------------------------------------------------------------------

  /// Builds the bounded keyword set stored on a blog for `array-contains`
  /// keyword search. Tokens come from the title, tags and author name; the set
  /// is capped so the field can never bloat the document.
  static List<String> buildKeywords(Blog blog) {
    final tokens = <String>{};
    void addAll(String source) {
      for (final raw in source.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
        if (raw.length >= 2) tokens.add(raw);
      }
    }

    addAll(blog.title);
    addAll(blog.authorName);
    for (final t in blog.tags) {
      addAll(t);
    }
    return tokens.take(40).toList();
  }

  // ---------------------------------------------------------------------------
  // Timestamp helpers
  // ---------------------------------------------------------------------------

  static Timestamp _tsFromIso(DateTime value) => Timestamp.fromDate(value);

  static Timestamp? _tsOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);

  /// Normalizes a stored date (Firestore [Timestamp], ISO [String], or an
  /// unresolved server-timestamp `null`) into the ISO string the models expect.
  static String? _isoOrNull(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}
