# Firestore Data Layer

Production persistence for the **blog module** (users, blogs, comments, likes,
bookmarks, search). This document explains the data model and the design
decisions the implementation makes — especially the scalability trade-offs.

> **Naming note.** The `users` collection stores `AppUser` (the app-level
> profile / blog identity). The cycle-tracking `UserModel` `ChangeNotifier` is a
> separate concern (local cycle data) and is intentionally **not** part of this
> relational layer — none of the requested user↔blog relationships apply to it.

## Architecture

Everything sits behind two interfaces, so the backend is swappable with a
one-line config change (`AppConfig.blogBackend`) and nothing above the interface
changes:

| Interface | Mock (dev/tests) | Production |
|---|---|---|
| `BlogRepository` | `MockBlogRepository` | `FirestoreBlogRepository` |
| `BlogSearchRepository` | `InMemoryBlogSearchRepository` | `FirestoreBlogSearchRepository` |
| `UserRepository` | `LocalUserRepository` | `FirestoreUserRepository` |

The models (`AppUser`, `Blog`, `Comment`, `BlogCategory`) stay **pure Dart** —
no `cloud_firestore` import — so they are unit-testable and backend-agnostic.
All Firestore-specific concerns (Timestamps, `DocumentReference`s, search-index
fields) live at the boundary in `FirestoreConverters`.

## Collection layout

```
users/{uid}                       AppUser  (doc id == Firebase Auth UID)
  ├─ bookmarks/{blogId}           { blogRef, createdAt }      private saves
  ├─ likedBlogs/{blogId}          { blogRef, createdAt }      reverse index of a like
  ├─ likedComments/{commentId}    { createdAt }               reverse index of a comment like
  ├─ commentedBlogs/{blogId}      { blogRef, commentCount, lastCommentAt }
  └─ readingProgress/{blogId}     { blogRef, progress, updatedAt }

blogs/{blogId}                    Blog + authorRef + titleLower/authorNameLower/keywords + engagementScore
  └─ likes/{uid}                  { userRef, createdAt }      one doc == one like

comments/{commentId}              Comment + blogRef + authorRef   (TOP-LEVEL — see below)
  └─ likes/{uid}                  { createdAt }

categories/{categoryId}           BlogCategory (read-only taxonomy)
blogReports/{reportId}            moderation queue (write-only for reporters)
```

## Key decisions & trade-offs

### 1. Likes & bookmarks → relationship docs + denormalized counters
We store **one document per (user, blog) edge**, never arrays of ids on the blog
or user document.

* *Why not arrays?* A viral post would push a `likedBy: [...]` array past
  Firestore's 1 MiB document limit and force the whole array to be rewritten on
  every like (write contention + cost). Arrays also can't paginate.
* Each like writes `blogs/{id}/likes/{uid}` **and** a reverse index
  `users/{uid}/likedBlogs/{blogId}`, so both *"who liked this blog"* and
  *"what has this user liked"* are keyed lookups.
* The `blogs/{id}.likeCount` (and `engagementScore`) counter is updated in the
  **same transaction**, so reads never aggregate the subcollection.
* **Bookmarks are private**, so they live only under the user
  (`users/{uid}/bookmarks`) with a `bookmarkCount` rollup — no blog-side data.

This is the *"combination of denormalized counters and relationship documents"*
option, chosen because it is the only one that stays correct **and** scalable at
high fan-out.

### 2. Comments → a **top-level** `comments` collection (not a subcollection)
The `BlogRepository` contract addresses comments by id alone
(`deleteComment(commentId)`, `toggleCommentLike(commentId, userId)`) — no blogId.

* A `blogs/{id}/comments/{commentId}` **subcollection** would need the blogId to
  build the document path, forcing a `collectionGroup` lookup on every
  delete/like (extra reads) or a change to the interface.
* A **top-level** collection keyed by comment id is directly addressable, still
  scales (comments are never embedded in the blog doc), paginates via a
  `(blogId ==, parentCommentId ==, createdAt desc)` index, and is friendlier to
  moderation (one place to scan/flag).
* **Trade-off:** we lose data locality and automatic cascade when a blog is
  deleted. Mitigation: soft-delete keeps blogs around; a Cloud Function can
  tombstone a blog's comments on hard removal.

Threading uses `parentCommentId` (null = top-level). Deletes are **soft**
(`status = deleted`, content cleared) so reply threads survive.

### 3. Pagination → `limit()` + `startAfterDocument()`
The `Page<T>.nextCursor` is an **opaque `String`** so callers never depend on the
paging mechanism. `CursorStore` bridges that opaque token to the
`DocumentSnapshot` Firestore's `startAfterDocument` needs, evicting old entries
so it can't grow unbounded. Every list (feed, rails, bookmarks, comments,
search) uses this.

### 4. Search → dedicated layer, prefix queries
Firestore has **no native full-text search**. `FirestoreBlogSearchRepository`
does index-backed **prefix** matching on denormalized `titleLower` /
`authorNameLower` fields (`where(field >= q && field < q+)`), paginated.

* **Pros:** cheap (O(results) reads), no extra infrastructure, fully paginated.
* **Cons:** prefix only (won't match infixes like "mones" → "Hormones"), no
  typo tolerance, no relevance ranking.
* **Production upgrade path:** mirror blogs into Algolia/Typesense/Elasticsearch
  via a Cloud Function and implement the same `BlogSearchRepository` interface
  against it — a one-file swap. A `keywords` token array is also written on each
  blog to enable `array-contains` whole-word search without changing the schema.

### 5. Counters ownership (avoiding double counts)
`postCount` / `commentCount` are bumped by the UI via `AuthController`; the
Firestore repo therefore owns only the **blog-side** counters, the relationship
subcollections, and `bookmarkCount` / `likeCount` (which nothing else touched),
each mutated atomically with its relationship write.

### 6. Robustness
* **Offline:** Firestore persistence is enabled in `main`; reads fall back to the
  local cache on a mid-call network drop (`readWithCacheFallback`), writes queue
  and replay automatically. Best-effort telemetry (views, reading progress)
  never surfaces errors.
* **Typed failures:** every call normalizes errors to `RepositoryException`
  (`network` / `permissionDenied` / `notFound` / `unknown`) so the UI can branch
  without importing `cloud_firestore`.
* **Forward compatibility:** reads go through the models' `fromMap`, which
  defaults every missing/nullable field, so documents written before a field
  existed still deserialize (covered by tests).
* **Deactivation over deletion:** users are soft-deactivated (`isActive`) and
  blogs/comments soft-deleted, so content stays attributable and restorable.

## Operating it

```bash
# Deploy rules + indexes (requires firebase-tools, project petal-a1290)
firebase deploy --only firestore:rules,firestore:indexes
```

* `firestore.rules` — ownership + counter-field rules (see file for the
  hardening note on moving counters to Cloud Functions).
* `firestore.indexes.json` — every composite index the queries above need.
* **Seeding:** in **debug** builds `FirestoreSeeder.seedIfEmpty()` uploads the
  canonical demo dataset (categories, the *Petal* author, demo blogs) the first
  time the `blogs` collection is empty; it never runs in release and never
  clobbers existing data.

## Tested

`test/blog_data_layer_test.dart` covers the backend-agnostic surface: model
round-trips, legacy-document defaulting, and the search dispatcher/pagination.
The Firestore repository is intended to be exercised against the Firebase
Emulator Suite in CI.
