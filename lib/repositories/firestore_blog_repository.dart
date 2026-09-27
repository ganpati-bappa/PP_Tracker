import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';
import 'package:pp_tracker/models/blog/blog_models.dart';
import 'package:pp_tracker/models/blog/comment.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';
import 'package:pp_tracker/repositories/firestore/firestore_converters.dart';
import 'package:pp_tracker/repositories/firestore/firestore_paths.dart';
import 'package:pp_tracker/repositories/firestore/firestore_support.dart';

/// Cloud Firestore implementation of [BlogRepository].
///
/// This is the production data layer for the blog module. It maps the domain
/// models onto the collection layout documented in [Fs], and is a drop-in
/// replacement for `MockBlogRepository` — the controllers and UI above the
/// [BlogRepository] interface need no changes.
///
/// ### Design highlights
/// * **Relationships, not arrays.** Likes and bookmarks are one-document-per-edge
///   (`blogs/{id}/likes/{uid}`, `users/{uid}/bookmarks/{blogId}`) with reverse
///   indexes so both "who liked X" and "what did U like" are cheap, and neither
///   the blog nor the user document can grow unbounded.
/// * **Denormalized counters.** `likeCount`, `commentCount`, `viewCount` and an
///   `engagementScore` live on the blog doc and are mutated atomically alongside
///   the relationship writes (transactions / batches) so reads never aggregate.
/// * **Real pagination.** Every list uses `limit()` + `startAfterDocument()` via
///   an opaque cursor (see [CursorStore]).
/// * **Offline-first.** Firestore's local cache serves reads offline; writes
///   queue and replay. Reads additionally fall back to the cache on a mid-call
///   network drop (see [readWithCacheFallback]).
/// * **Typed failures.** Everything is normalized to [RepositoryException].
class FirestoreBlogRepository implements BlogRepository {
  FirestoreBlogRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final CursorStore _cursors = CursorStore();

  String? _currentUserId;

  CollectionReference<Map<String, dynamic>> get _blogs =>
      _db.collection(Fs.blogs);
  CollectionReference<Map<String, dynamic>> get _commentsCol =>
      _db.collection(Fs.comments);
  CollectionReference<Map<String, dynamic>> get _categoriesCol =>
      _db.collection(Fs.categories);

  @override
  void setCurrentUser(String? userId) => _currentUserId = userId;

  // ===========================================================================
  // Reading
  // ===========================================================================

  @override
  Future<List<BlogCategory>> fetchCategories() async {
    final snap = await readWithCacheFallback(
      (opts) => _categoriesCol.orderBy('sortOrder').get(opts),
      context: 'load categories',
    );
    return snap.docs
        .map((d) => BlogCategory.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<Page<Blog>> fetchBlogs({
    BlogQuery query = const BlogQuery(),
    String? cursor,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> q = _blogs
        .where('isDeleted', isEqualTo: false)
        .where('visibility', isEqualTo: query.visibility.name);

    if (query.categoryId != null &&
        query.categoryId != BlogCategory.all.id) {
      q = q.where('categoryId', isEqualTo: query.categoryId);
    }
    if (query.tag != null) {
      q = q.where('tags', arrayContains: query.tag);
    }

    final term = query.searchTerm?.trim().toLowerCase();
    if (term != null && term.isNotEmpty) {
      // Prefix search on the normalized title (see BlogSearchRepository for the
      // dedicated title + author search surface). A range query must order by
      // the same field; U+F8FF is the conventional high-codepoint upper bound
      // that matches every title beginning with `term`.
      q = q.orderBy('titleLower').startAt([term]).endAt(['$term']);
    } else {
      switch (query.sort) {
        case BlogSort.latest:
          q = q.orderBy('publishedAt', descending: true);
          break;
        case BlogSort.trending:
          q = q.orderBy('engagementScore', descending: true);
          break;
        case BlogSort.mostViewed:
          q = q.orderBy('viewCount', descending: true);
          break;
      }
    }

    return _paginate(q, scope: 'feed:${query.hashCode}', cursor: cursor,
        limit: limit, context: 'load articles');
  }

  @override
  Future<Blog?> fetchBlogById(String id) async {
    final snap = await readWithCacheFallback(
      (opts) => _blogs.doc(id).get(opts),
      context: 'open this article',
    );
    if (!snap.exists || (snap.data()?['isDeleted'] == true)) return null;
    final decorated = await _decorateBlogs([FirestoreConverters.blogFromFirestore(snap)]);
    return decorated.first;
  }

  @override
  Future<List<Blog>> fetchFeatured({int limit = 5}) async {
    final snap = await readWithCacheFallback(
      (opts) => _publicBlogs()
          .where('isFeatured', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get(opts),
      context: 'load featured articles',
    );
    return _decorateBlogs(snap.docs.map(FirestoreConverters.blogFromFirestore).toList());
  }

  @override
  Future<List<Blog>> fetchTrending({int limit = 6}) async {
    final snap = await readWithCacheFallback(
      (opts) => _publicBlogs()
          .orderBy('engagementScore', descending: true)
          .limit(limit)
          .get(opts),
      context: 'load trending articles',
    );
    return _decorateBlogs(snap.docs.map(FirestoreConverters.blogFromFirestore).toList());
  }

  @override
  Future<List<Blog>> fetchRecommended({String? forUserId, int limit = 6}) async {
    // A lightweight personalization: bias toward the categories the user has
    // been reading, falling back to trending. A production recommender would
    // run server-side; this keeps client reads bounded.
    final categoryIds = await _recentlyReadCategories(forUserId, sample: 10);
    if (categoryIds.isEmpty) return fetchTrending(limit: limit);

    // Firestore `whereIn` supports up to 10 values — categoryIds is already
    // capped by the sample size above.
    final snap = await readWithCacheFallback(
      (opts) => _publicBlogs()
          .where('categoryId', whereIn: categoryIds.take(10).toList())
          .orderBy('engagementScore', descending: true)
          .limit(limit)
          .get(opts),
      context: 'load recommendations',
    );
    return _decorateBlogs(snap.docs.map(FirestoreConverters.blogFromFirestore).toList());
  }

  @override
  Future<List<Blog>> fetchRelated(Blog blog, {int limit = 3}) async {
    final snap = await readWithCacheFallback(
      (opts) => _publicBlogs()
          .where('categoryId', isEqualTo: blog.categoryId)
          .orderBy('engagementScore', descending: true)
          .limit(limit + 1) // +1 so we can drop the article itself
          .get(opts),
      context: 'load related articles',
    );
    final related = snap.docs
        .map(FirestoreConverters.blogFromFirestore)
        .where((b) => b.id != blog.id)
        .take(limit)
        .toList();
    return _decorateBlogs(related);
  }

  // ===========================================================================
  // Per-user state: bookmarks, likes, views, reading progress
  // ===========================================================================

  @override
  Future<void> setBookmark(String blogId, String userId, bool bookmarked) {
    // A bookmark is a single relationship document under the user's private
    // subcollection — its existence *is* the bookmark. No counter to maintain.
    final bookmarkRef =
        Fs.userRef(_db, userId).collection(Fs.bookmarks).doc(blogId);

    return runWrite(
      () => _db.runTransaction((tx) async {
        final existing = await tx.get(bookmarkRef);
        if (bookmarked && !existing.exists) {
          tx.set(bookmarkRef, {
            'blogRef': Fs.blogRef(_db, blogId),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else if (!bookmarked && existing.exists) {
          tx.delete(bookmarkRef);
        }
      }),
      context: 'save this bookmark',
    );
  }

  @override
  Future<List<Blog>> fetchBookmarks(String userId) async {
    final snap = await readWithCacheFallback(
      (opts) => Fs.userRef(_db, userId)
          .collection(Fs.bookmarks)
          .orderBy('createdAt', descending: true)
          .get(opts),
      context: 'load your saved articles',
    );
    final ids = snap.docs.map((d) => d.id).toList();
    final blogs = await _fetchBlogsByIds(ids);
    return _decorateBlogs(blogs);
  }

  @override
  Future<List<Blog>> fetchLikedBlogs(String userId, {int limit = 50}) async {
    final snap = await readWithCacheFallback(
      (opts) => Fs.userRef(_db, userId)
          .collection(Fs.likedBlogs)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get(opts),
      context: 'load blogs you liked',
    );
    final ids = snap.docs.map((d) => d.id).toList();
    return _decorateBlogs(await _fetchBlogsByIds(ids));
  }

  @override
  Future<List<Blog>> fetchAuthoredBlogs(String userId, {int limit = 50}) async {
    // Relationship by query — no array on the user doc. Backed by the
    // (authorId ASC, publishedAt DESC) composite index in firestore.indexes.json.
    final snap = await readWithCacheFallback(
      (opts) => _blogs
          .where('authorId', isEqualTo: userId)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get(opts),
      context: 'load your articles',
    );
    final authored = snap.docs
        .where((d) => d.data()['isDeleted'] != true)
        .map(FirestoreConverters.blogFromFirestore)
        .toList();
    return _decorateBlogs(authored);
  }

  @override
  Future<void> toggleLike(String blogId, String userId) {
    final likeRef = _blogs.doc(blogId).collection(Fs.likes).doc(userId);
    final reverseRef =
        Fs.userRef(_db, userId).collection(Fs.likedBlogs).doc(blogId);
    final blogRef = _blogs.doc(blogId);
    final userRef = Fs.userRef(_db, userId);

    return runWrite(
      () => _db.runTransaction((tx) async {
        final existing = await tx.get(likeRef);
        final delta = existing.exists ? -1 : 1;

        if (existing.exists) {
          tx.delete(likeRef);
          tx.delete(reverseRef);
        } else {
          tx.set(likeRef, {
            'userRef': userRef,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tx.set(reverseRef, {
            'blogRef': blogRef,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        // The blog's own like tally is a legitimate denormalized counter (it's
        // rendered on every card), kept in the same atomic unit as the edge.
        // No per-user counter — "blogs I liked" is the likedBlogs subcollection.
        tx.set(
          blogRef,
          {
            'likeCount': FieldValue.increment(delta),
            'engagementScore': FieldValue.increment(2.0 * delta),
          },
          SetOptions(merge: true),
        );
      }),
      context: 'update your like',
    );
  }

  @override
  Future<void> recordView(String blogId, String userId) async {
    // Best-effort telemetry: a failed view count must never surface an error.
    try {
      await _blogs.doc(blogId).set({
        'viewCount': FieldValue.increment(1),
        'engagementScore': FieldValue.increment(0.4),
      }, SetOptions(merge: true));
    } catch (_) {
      // Swallow — offline writes queue automatically; other failures are noise.
    }
  }

  @override
  Future<void> saveReadingProgress(
      String blogId, String userId, double progress) async {
    try {
      await Fs.userRef(_db, userId)
          .collection(Fs.readingProgress)
          .doc(blogId)
          .set({
        'blogRef': Fs.blogRef(_db, blogId),
        'progress': progress.clamp(0.0, 1.0),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort; reading position is a convenience.
    }
  }

  @override
  Future<List<Blog>> fetchContinueReading(String userId, {int limit = 5}) async {
    // Over-fetch a little, then keep only in-progress entries client-side (the
    // 0.02–0.95 band isn't expressible as a single ordered Firestore query).
    final snap = await readWithCacheFallback(
      (opts) => Fs.userRef(_db, userId)
          .collection(Fs.readingProgress)
          .orderBy('updatedAt', descending: true)
          .limit(limit * 4)
          .get(opts),
      context: 'load your reading list',
    );
    final ids = snap.docs
        .where((d) {
          final p = (d.data()['progress'] as num?)?.toDouble() ?? 0;
          return p > 0.02 && p < 0.95;
        })
        .map((d) => d.id)
        .take(limit)
        .toList();
    return _decorateBlogs(await _fetchBlogsByIds(ids));
  }

  @override
  Future<List<Blog>> fetchReadingHistory(String userId, {int limit = 20}) async {
    final snap = await readWithCacheFallback(
      (opts) => Fs.userRef(_db, userId)
          .collection(Fs.readingProgress)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get(opts),
      context: 'load your history',
    );
    return _decorateBlogs(await _fetchBlogsByIds(snap.docs.map((d) => d.id).toList()));
  }

  // ===========================================================================
  // Authoring & moderation
  // ===========================================================================

  @override
  Future<Blog> upsertBlog(Blog blog) {
    final ref = _blogs.doc(blog.id);
    return runWrite(
      () => _db.runTransaction((tx) async {
        final existing = await tx.get(ref);
        tx.set(
          ref,
          FirestoreConverters.blogToFirestore(blog, _db,
              isCreate: !existing.exists),
          SetOptions(merge: true),
        );
        return blog;
      }),
      context: 'publish this article',
    );
  }

  @override
  Future<void> deleteBlog(String blogId) => runWrite(
        () => _blogs.doc(blogId).set({
          'isDeleted': true,
          'visibility': BlogVisibility.archived.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        context: 'delete this article',
      );

  @override
  Future<void> reportBlog(BlogReport report) {
    final ref = report.id.isEmpty
        ? _db.collection(Fs.blogReports).doc()
        : _db.collection(Fs.blogReports).doc(report.id);
    return runWrite(
      () => ref.set({
        ...report.toMap(),
        'id': ref.id,
        'blogRef': Fs.blogRef(_db, report.blogId),
        'reporterRef': Fs.userRef(_db, report.reporterId),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
      }),
      context: 'submit this report',
    );
  }

  // ===========================================================================
  // Comments (top-level `comments` collection — see design doc)
  // ===========================================================================

  @override
  Future<Page<Comment>> fetchComments(
    String blogId, {
    String? parentCommentId,
    String? cursor,
    int limit = 20,
  }) async {
    final q = _commentsCol
        .where('blogId', isEqualTo: blogId)
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: true);

    final page = await _paginateRaw(
      q,
      scope: 'comments:$blogId:${parentCommentId ?? 'root'}',
      cursor: cursor,
      limit: limit,
      context: 'load comments',
    );

    // Drop moderator-hidden comments (deleted are kept as tombstones).
    final comments = page.docs
        .map(FirestoreConverters.commentFromFirestore)
        .where((c) => c.status != CommentStatus.hidden)
        .toList();

    return Page(
      items: await _decorateComments(comments),
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<Comment> addComment({
    required String blogId,
    required AppUser author,
    required String content,
    String? parentCommentId,
  }) {
    final ref = _commentsCol.doc();
    final now = DateTime.now();
    final comment = Comment(
      id: ref.id,
      blogId: blogId,
      userId: author.id,
      authorName: author.displayName,
      authorAvatarUrl: author.avatarUrl,
      parentCommentId: parentCommentId,
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
    );

    return runWrite(
      () async {
        final batch = _db.batch()
          ..set(ref, FirestoreConverters.commentToFirestore(comment, _db))
          ..set(
            _blogs.doc(blogId),
            {
              'commentCount': FieldValue.increment(1),
              'engagementScore': FieldValue.increment(3.0),
            },
            SetOptions(merge: true),
          )
          // Reverse index: "blogs this user has commented on".
          ..set(
            Fs.userRef(_db, author.id).collection(Fs.commentedBlogs).doc(blogId),
            {
              'blogRef': Fs.blogRef(_db, blogId),
              'commentCount': FieldValue.increment(1),
              'lastCommentAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

        if (parentCommentId != null) {
          batch.set(
            _commentsCol.doc(parentCommentId),
            {'replyCount': FieldValue.increment(1)},
            SetOptions(merge: true),
          );
        }

        await batch.commit();
        return comment;
      },
      context: 'post your comment',
    );
  }

  @override
  Future<void> toggleCommentLike(String commentId, String userId) {
    final likeRef =
        _commentsCol.doc(commentId).collection(Fs.likes).doc(userId);
    final reverseRef = Fs.userRef(_db, userId)
        .collection('likedComments')
        .doc(commentId);
    final commentRef = _commentsCol.doc(commentId);

    return runWrite(
      () => _db.runTransaction((tx) async {
        final existing = await tx.get(likeRef);
        final delta = existing.exists ? -1 : 1;
        if (existing.exists) {
          tx.delete(likeRef);
          tx.delete(reverseRef);
        } else {
          tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
          tx.set(reverseRef, {'createdAt': FieldValue.serverTimestamp()});
        }
        tx.set(commentRef, {'likeCount': FieldValue.increment(delta)},
            SetOptions(merge: true));
      }),
      context: 'update your like',
    );
  }

  @override
  Future<void> deleteComment(String commentId) {
    // Soft delete: tombstone the content but keep the node so reply threads and
    // moderation history survive (mirrors CommentStatus.deleted).
    return runWrite(
      () => _commentsCol.doc(commentId).set({
        'status': CommentStatus.deleted.name,
        'content': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      context: 'delete this comment',
    );
  }

  // ===========================================================================
  // Users
  // ===========================================================================

  @override
  Future<AppUser?> fetchUser(String id) async {
    final snap = await readWithCacheFallback(
      (opts) => Fs.userRef(_db, id).get(opts),
      context: 'load this profile',
    );
    return FirestoreConverters.appUserFromFirestore(snap);
  }

  // ===========================================================================
  // Internals
  // ===========================================================================

  Query<Map<String, dynamic>> _publicBlogs() => _blogs
      .where('isDeleted', isEqualTo: false)
      .where('visibility', isEqualTo: BlogVisibility.public.name);

  /// Reads one page and maps + decorates each doc into a [Blog].
  Future<Page<Blog>> _paginate(
    Query<Map<String, dynamic>> query, {
    required String scope,
    required String? cursor,
    required int limit,
    required String context,
  }) async {
    final raw = await _paginateRaw(query,
        scope: scope, cursor: cursor, limit: limit, context: context);
    final blogs =
        raw.docs.map(FirestoreConverters.blogFromFirestore).toList();
    return Page(items: await _decorateBlogs(blogs), nextCursor: raw.nextCursor);
  }

  /// The generic paging primitive: applies `startAfterDocument` + `limit`, and
  /// hands back a fresh opaque cursor when a full page came back.
  Future<_RawPage> _paginateRaw(
    Query<Map<String, dynamic>> query, {
    required String scope,
    required String? cursor,
    required int limit,
    required String context,
  }) async {
    var q = query;
    final startAfter = _cursors.resolve(cursor);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    q = q.limit(limit);

    final snap =
        await readWithCacheFallback((opts) => q.get(opts), context: context);
    final docs = snap.docs;
    final nextCursor = docs.length == limit
        ? _cursors.remember(scope, docs.last)
        : null;
    return _RawPage(docs, nextCursor);
  }

  /// Decorates blogs with the current user's like/bookmark state using at most
  /// two `whereIn` reads per page (never a per-item read).
  Future<List<Blog>> _decorateBlogs(List<Blog> blogs) async {
    final uid = _currentUserId;
    if (uid == null || blogs.isEmpty) return blogs;
    final ids = blogs.map((b) => b.id).toList();

    final likedIds =
        await _idsPresent(Fs.userRef(_db, uid).collection(Fs.likedBlogs), ids);
    final bookmarkedIds =
        await _idsPresent(Fs.userRef(_db, uid).collection(Fs.bookmarks), ids);

    return blogs
        .map((b) => b.copyWith(
              isLikedByMe: likedIds.contains(b.id),
              isBookmarked: bookmarkedIds.contains(b.id),
            ))
        .toList();
  }

  Future<List<Comment>> _decorateComments(List<Comment> comments) async {
    final uid = _currentUserId;
    if (uid == null || comments.isEmpty) return comments;
    final ids = comments.map((c) => c.id).toList();
    final likedIds = await _idsPresent(
        Fs.userRef(_db, uid).collection('likedComments'), ids);
    return comments
        .map((c) => c.copyWith(isLikedByMe: likedIds.contains(c.id)))
        .toList();
  }

  /// Returns which of [ids] exist as documents in [collection], batching the
  /// lookups into `whereIn` chunks of 10 (Firestore's limit).
  Future<Set<String>> _idsPresent(
    CollectionReference<Map<String, dynamic>> collection,
    List<String> ids,
  ) async {
    final present = <String>{};
    for (final chunk in _chunk(ids, 10)) {
      final snap = await readWithCacheFallback(
        (opts) =>
            collection.where(FieldPath.documentId, whereIn: chunk).get(opts),
        context: 'load your activity',
      );
      present.addAll(snap.docs.map((d) => d.id));
    }
    return present;
  }

  /// Fetches blogs by id in `whereIn` chunks, preserving the input order and
  /// silently dropping missing/soft-deleted ones.
  Future<List<Blog>> _fetchBlogsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final byId = <String, Blog>{};
    for (final chunk in _chunk(ids, 10)) {
      final snap = await readWithCacheFallback(
        (opts) =>
            _blogs.where(FieldPath.documentId, whereIn: chunk).get(opts),
        context: 'load articles',
      );
      for (final d in snap.docs) {
        if (d.data()['isDeleted'] == true) continue;
        byId[d.id] = FirestoreConverters.blogFromFirestore(d);
      }
    }
    return ids.map((id) => byId[id]).whereType<Blog>().toList();
  }

  Future<List<String>> _recentlyReadCategories(String? userId,
      {int sample = 10}) async {
    if (userId == null) return const [];
    final progress = await readWithCacheFallback(
      (opts) => Fs.userRef(_db, userId)
          .collection(Fs.readingProgress)
          .orderBy('updatedAt', descending: true)
          .limit(sample)
          .get(opts),
      context: 'load recommendations',
    );
    final blogs = await _fetchBlogsByIds(progress.docs.map((d) => d.id).toList());
    // Preserve recency order, dedupe categories.
    final seen = <String>{};
    for (final b in blogs) {
      seen.add(b.categoryId);
    }
    return seen.toList();
  }

  static Iterable<List<T>> _chunk<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }
}

/// A page of raw Firestore docs plus the opaque cursor to continue from.
class _RawPage {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String? nextCursor;
  const _RawPage(this.docs, this.nextCursor);
}
