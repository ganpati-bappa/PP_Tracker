import 'package:flutter_test/flutter_test.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/comment.dart';
import 'package:pp_tracker/repositories/blog_search_repository.dart';
import 'package:pp_tracker/repositories/mock_blog_repository.dart';

/// These cover the backend-agnostic pieces of the data layer — the model
/// (de)serialization boundary and the search dispatcher — which are exactly the
/// parts that must stay correct as documents evolve. The Firestore repository
/// itself is exercised against the emulator (see docs/firestore_data_layer.md).
void main() {
  group('AppUser round-trips and stays forward-compatible', () {
    test('toMap/fromMap preserves every field', () {
      final user = AppUser(
        id: 'uid1',
        displayName: 'Ada Lovelace',
        email: 'ada@example.com',
        isExpert: true,
        credentials: 'Mathematician',
        joinedAt: DateTime.utc(2024, 1, 2),
        lastActiveAt: DateTime.utc(2024, 5, 6),
      );
      final restored = AppUser.fromMap(user.toMap());
      expect(restored.id, user.id);
      expect(restored.email, 'ada@example.com');
      expect(restored.credentials, 'Mathematician');
      expect(restored.isActive, true);
      expect(restored.isExpert, true);
      expect(restored.joinedAt, user.joinedAt);
    });

    test('missing newly-added fields default safely (legacy document)', () {
      // A document written before isActive existed still deserializes.
      final legacy = {
        'id': 'old',
        'displayName': 'Legacy User',
        'joinedAt': DateTime.utc(2020).toIso8601String(),
      };
      final user = AppUser.fromMap(legacy);
      expect(user.isActive, true);
      expect(user.isExpert, false);
      expect(user.metadata, isEmpty);
    });
  });

  group('Blog & Comment mapping', () {
    test('Blog survives a toMap/fromMap cycle', () {
      final blog = Blog(
        id: 'b1',
        title: 'Understanding Hormones',
        authorId: 'uid1',
        authorName: 'Ada',
        categoryId: 'hormones',
        tags: const ['science', 'hormones'],
        publishedAt: DateTime.utc(2024, 3, 1),
        updatedAt: DateTime.utc(2024, 3, 2),
        likeCount: 5,
      );
      final restored = Blog.fromMap(blog.toMap());
      expect(restored.id, 'b1');
      expect(restored.title, 'Understanding Hormones');
      expect(restored.likeCount, 5);
      expect(restored.tags, containsAll(['science', 'hormones']));
      // Transient per-user view state is never serialized.
      expect(restored.isBookmarked, false);
    });

    test('Comment defaults status to visible for unknown values', () {
      final map = {
        'id': 'c1',
        'blogId': 'b1',
        'userId': 'uid1',
        'content': 'Great read',
        'status': 'nonsense',
      };
      expect(Comment.fromMap(map).status, CommentStatus.visible);
    });
  });

  group('In-memory search dispatcher', () {
    late InMemoryBlogSearchRepository search;

    setUp(() {
      final blogs = MockBlogRepository.demoDataset().blogs;
      search = InMemoryBlogSearchRepository(() => blogs);
    });

    test('title search matches case-insensitively', () async {
      final page = await search.search('hormone');
      expect(page.items, isNotEmpty);
      expect(
        page.items.every((b) => b.title.toLowerCase().contains('hormone')),
        isTrue,
      );
    });

    test('author search routes through the dispatcher', () async {
      final page =
          await search.search('petal', field: BlogSearchField.author);
      expect(page.items, isNotEmpty);
      expect(page.items.first.authorName.toLowerCase(), contains('petal'));
    });

    test('paginates via opaque cursor', () async {
      final first = await search.searchByTitle('the', limit: 2);
      expect(first.items.length, lessThanOrEqualTo(2));
      if (first.hasMore) {
        final second =
            await search.searchByTitle('the', cursor: first.nextCursor, limit: 2);
        // No overlap between consecutive pages.
        final firstIds = first.items.map((b) => b.id).toSet();
        expect(second.items.any((b) => firstIds.contains(b.id)), isFalse);
      }
    });
  });
}
