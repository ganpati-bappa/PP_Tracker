import 'package:cloud_firestore/cloud_firestore.dart';

/// Central definition of the Firestore collection/field layout.
///
/// Keeping every path in one place means the data model is documented in a
/// single file and there are no stringly-typed collection names scattered
/// across the repositories.
///
/// ## Collection map
///
/// ```
/// users/{uid}                                  (AppUser profile)
///   ├─ bookmarks/{blogId}       -> { blogRef, createdAt }   (private saves)
///   ├─ likedBlogs/{blogId}      -> { blogRef, createdAt }   (reverse index of a like)
///   ├─ commentedBlogs/{blogId}  -> { blogRef, commentCount, lastCommentAt }
///   └─ readingProgress/{blogId} -> { blogRef, progress, updatedAt }
///
/// blogs/{blogId}                               (Blog document)
///   └─ likes/{uid}              -> { userRef, createdAt }   (one doc == one like)
///
/// comments/{commentId}                         (top-level, see design doc)
///   └─ likes/{uid}              -> { createdAt }
///
/// categories/{categoryId}                      (BlogCategory)
///
/// blogReports/{reportId}                       (BlogReport, moderation queue)
/// ```
///
/// Likes and bookmarks are modelled as **relationship documents** (one doc per
/// (user, blog) edge) plus **denormalized counters** on the parent docs — never
/// as unbounded arrays on the blog or user document. This keeps documents well
/// under Firestore's 1 MiB limit and makes "did this user like X?" a single
/// keyed lookup instead of scanning an array.
class Fs {
  Fs._();

  // ---- Top-level collections ----------------------------------------------
  static const users = 'users';
  static const blogs = 'blogs';
  static const comments = 'comments';
  static const categories = 'categories';
  static const blogReports = 'blogReports';

  // ---- Subcollections ------------------------------------------------------
  static const bookmarks = 'bookmarks';
  static const likedBlogs = 'likedBlogs';
  static const commentedBlogs = 'commentedBlogs';
  static const readingProgress = 'readingProgress';
  static const likes = 'likes';

  // ---- Reference builders --------------------------------------------------
  static DocumentReference<Map<String, dynamic>> userRef(
          FirebaseFirestore db, String uid) =>
      db.collection(users).doc(uid);

  static DocumentReference<Map<String, dynamic>> blogRef(
          FirebaseFirestore db, String blogId) =>
      db.collection(blogs).doc(blogId);

  static DocumentReference<Map<String, dynamic>> commentRef(
          FirebaseFirestore db, String commentId) =>
      db.collection(comments).doc(commentId);
}
