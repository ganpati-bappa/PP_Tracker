import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/repositories/blog_repository.dart' show Page;

/// Which indexed field a query runs against.
enum BlogSearchField { title, author }

/// A dedicated search surface for blogs, separate from the browsing/feed
/// [BlogRepository] so the two can evolve independently (the feed is about
/// ordering & rails; search is about matching text).
///
/// ### Why a separate layer, and the Firestore trade-off
/// Firestore has **no native full-text / substring search**. The scalable
/// primitives it *does* offer are:
///  * range queries on a normalized field (`titleLower >= q && < q+`) →
///    great for **prefix** matching ("hor" → "Hormones"), O(results) reads.
///  * `array-contains` on a precomputed keyword set → whole-token matching.
///
/// [FirestoreBlogSearchRepository] uses the prefix approach on the denormalized
/// `titleLower` / `authorNameLower` fields the write path maintains. This is
/// cheap, paginated and index-backed. Its limitation is that it matches
/// *prefixes*, not arbitrary infixes ("mones" won't find "Hormones") and does
/// no typo tolerance or relevance ranking.
///
/// For true full-text search (infix, fuzzy, ranked) the production path is to
/// mirror blogs into a search service (Algolia / Typesense / Elasticsearch) via
/// a Cloud Function and implement this same interface against it — no caller
/// changes. Keeping search behind this interface is exactly what makes that
/// swap a one-file change.
abstract class BlogSearchRepository {
  /// Scopes returned per-user view state; may be a no-op for pure search.
  void setCurrentUser(String? userId);

  /// Prefix search over blog titles, most-relevant/alphabetical first.
  Future<Page<Blog>> searchByTitle(
    String query, {
    String? cursor,
    int limit = 20,
  });

  /// Prefix search over author display names.
  Future<Page<Blog>> searchByAuthor(
    String authorName, {
    String? cursor,
    int limit = 20,
  });

}

/// Convenience dispatcher used by a single search box. Provided as an extension
/// so implementers only need to supply the two primitive queries (and so
/// `implements BlogSearchRepository` doesn't demand this method too).
extension BlogSearchDispatch on BlogSearchRepository {
  Future<Page<Blog>> search(
    String query, {
    BlogSearchField field = BlogSearchField.title,
    String? cursor,
    int limit = 20,
  }) {
    switch (field) {
      case BlogSearchField.title:
        return searchByTitle(query, cursor: cursor, limit: limit);
      case BlogSearchField.author:
        return searchByAuthor(query, cursor: cursor, limit: limit);
    }
  }
}

/// In-memory search over a supplied blog list. Intended for tests and the mock
/// backend so the search UI can be exercised without Firestore. Matches by
/// case-insensitive *substring* (more forgiving than the Firestore prefix impl,
/// which is fine for a small local dataset).
class InMemoryBlogSearchRepository implements BlogSearchRepository {
  InMemoryBlogSearchRepository(this._source);

  /// Supplies the current corpus (e.g. the mock repo's blog list).
  final List<Blog> Function() _source;

  @override
  void setCurrentUser(String? userId) {}

  @override
  Future<Page<Blog>> searchByTitle(String query,
          {String? cursor, int limit = 20}) =>
      _run((b) => b.title.toLowerCase().contains(query.trim().toLowerCase()),
          cursor: cursor, limit: limit);

  @override
  Future<Page<Blog>> searchByAuthor(String authorName,
          {String? cursor, int limit = 20}) =>
      _run(
          (b) => b.authorName
              .toLowerCase()
              .contains(authorName.trim().toLowerCase()),
          cursor: cursor,
          limit: limit);

  Future<Page<Blog>> _run(bool Function(Blog) test,
      {String? cursor, int limit = 20}) async {
    final all = _source()
        .where((b) => b.visibility.isPublic)
        .where(test)
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final offset = int.tryParse(cursor ?? '') ?? 0;
    final slice = all.skip(offset).take(limit).toList();
    final next = offset + slice.length;
    return Page(items: slice, nextCursor: next < all.length ? '$next' : null);
  }
}
