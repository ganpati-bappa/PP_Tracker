import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/repositories/firestore/firestore_converters.dart';
import 'package:pp_tracker/repositories/firestore/firestore_paths.dart';
import 'package:pp_tracker/repositories/mock_blog_repository.dart';

/// One-time, idempotent bootstrap of the Firestore `categories`, `users` and
/// `blogs` collections from the canonical demo dataset.
///
/// Intended for **development/staging** so a fresh Firebase project has browsable
/// content immediately. It is guarded two ways: the caller only runs it in debug
/// builds (see `main.dart`), and [seedIfEmpty] no-ops the moment any blog
/// already exists, so it will never duplicate or clobber real data.
class FirestoreSeeder {
  FirestoreSeeder({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Seeds only when the `blogs` collection is empty. Safe to call on every
  /// debug launch.
  Future<void> seedIfEmpty() async {
    final probe = await _db.collection(Fs.blogs).limit(1).get();
    if (probe.docs.isNotEmpty) return;

    final data = MockBlogRepository.demoDataset();
    final batch = _db.batch();

    for (final category in data.categories) {
      batch.set(_db.collection(Fs.categories).doc(category.id), category.toMap());
    }
    for (final user in data.users) {
      batch.set(Fs.userRef(_db, user.id), _userSeed(user));
    }
    for (final blog in data.blogs) {
      batch.set(
        Fs.blogRef(_db, blog.id),
        FirestoreConverters.blogToFirestore(blog, _db, isCreate: true),
      );
    }

    await batch.commit();
  }

  /// Seed users are written with native Timestamps to match the runtime schema
  /// produced by [FirestoreUserRepository].
  Map<String, dynamic> _userSeed(AppUser user) => user.toMap()
    ..['joinedAt'] = Timestamp.fromDate(user.joinedAt)
    ..['lastActiveAt'] =
        user.lastActiveAt == null ? null : Timestamp.fromDate(user.lastActiveAt!);
}
