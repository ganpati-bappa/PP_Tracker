import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/repositories/blog_repository.dart' show Page;
import 'package:pp_tracker/repositories/blog_search_repository.dart';
import 'package:pp_tracker/repositories/firestore/firestore_converters.dart';
import 'package:pp_tracker/repositories/firestore/firestore_paths.dart';
import 'package:pp_tracker/repositories/firestore/firestore_support.dart';

/// Firestore-backed [BlogSearchRepository].
///
/// Runs index-backed **prefix** queries over the denormalized `titleLower` /
/// `authorNameLower` fields written by [FirestoreConverters.blogToFirestore],
/// restricted to public, non-deleted articles. Results are paginated with
/// `limit()` + `startAfterDocument()` via the shared [CursorStore]. See
/// [BlogSearchRepository] for the trade-offs vs. a dedicated search service.
class FirestoreBlogSearchRepository implements BlogSearchRepository {
  FirestoreBlogSearchRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final CursorStore _cursors = CursorStore();

  // Retained for API parity; search results are returned without per-user
  // like/bookmark decoration (callers can hydrate via BlogRepository if needed).
  // ignore: unused_field
  String? _currentUserId;

  CollectionReference<Map<String, dynamic>> get _blogs =>
      _db.collection(Fs.blogs);

  @override
  void setCurrentUser(String? userId) => _currentUserId = userId;

  @override
  Future<Page<Blog>> searchByTitle(String query,
          {String? cursor, int limit = 20}) =>
      _prefixSearch('titleLower', query, cursor: cursor, limit: limit);

  @override
  Future<Page<Blog>> searchByAuthor(String authorName,
          {String? cursor, int limit = 20}) =>
      _prefixSearch('authorNameLower', authorName, cursor: cursor, limit: limit);

  Future<Page<Blog>> _prefixSearch(
    String field,
    String rawQuery, {
    String? cursor,
    int limit = 20,
  }) async {
    final term = rawQuery.trim().toLowerCase();
    if (term.isEmpty) return const Page.empty();

    // '' is a very high code point — `[term, term+]` bounds the
    // range to every value that starts with `term`.
    Query<Map<String, dynamic>> q = _blogs
        .where('isDeleted', isEqualTo: false)
        .where('visibility', isEqualTo: BlogVisibility.public.name)
        .orderBy(field)
        .startAt([term]).endAt(['$term']);

    final startAfter = _cursors.resolve(cursor);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    q = q.limit(limit);

    final snap = await readWithCacheFallback(
      (opts) => q.get(opts),
      context: 'search articles',
    );
    final blogs = snap.docs.map(FirestoreConverters.blogFromFirestore).toList();
    final nextCursor = snap.docs.length == limit
        ? _cursors.remember('search:$field:$term', snap.docs.last)
        : null;
    return Page(items: blogs, nextCursor: nextCursor);
  }
}
