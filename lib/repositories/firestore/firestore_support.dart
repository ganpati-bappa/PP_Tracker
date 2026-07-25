import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pp_tracker/repositories/repository_exception.dart';

/// Small building blocks shared by the Firestore repositories: an opaque-cursor
/// store for `startAfterDocument` pagination and an offline-aware read helper.

/// Translates the repository's opaque `String? cursor` contract onto Firestore's
/// [DocumentSnapshot]-based [Query.startAfterDocument] API.
///
/// The [Page]/`cursor` seam deliberately keeps cursors opaque so the UI never
/// depends on the paging mechanism. Firestore, however, needs the *last
/// document* of the previous page to fetch the next one. This cache hands out a
/// short token for each page boundary and remembers the matching snapshot,
/// evicting the oldest entries so it can never grow unbounded during a long
/// session.
class CursorStore {
  CursorStore({this.maxEntries = 256});

  final int maxEntries;
  int _seq = 0;
  final LinkedHashMap<String, DocumentSnapshot<Object?>> _snaps =
      LinkedHashMap();

  /// Registers [snap] as the boundary after page [scope] and returns its token.
  /// [scope] namespaces tokens per logical query so cursors never collide
  /// between, say, the main feed and a comment thread.
  String remember(String scope, DocumentSnapshot<Object?> snap) {
    final token = '$scope#${_seq++}';
    _snaps[token] = snap;
    if (_snaps.length > maxEntries) {
      _snaps.remove(_snaps.keys.first); // evict oldest (insertion order)
    }
    return token;
  }

  /// Resolves a token previously issued by [remember]. Returns null for an
  /// unknown/evicted token, in which case the caller simply starts from page 1.
  DocumentSnapshot<Object?>? resolve(String? token) =>
      token == null ? null : _snaps[token];
}

/// Runs a Firestore read with graceful offline behaviour.
///
/// Firestore's on-device cache already answers most reads offline, but a read
/// that reaches the network and fails (airplane mode mid-call) throws. This
/// helper retries such a read against the local cache before giving up, so a
/// flaky connection degrades to cached data instead of an error screen.
Future<T> readWithCacheFallback<T>(
  Future<T> Function(GetOptions? options) run, {
  String? context,
}) async {
  try {
    return await run(null); // default: server-first, falls back to cache
  } on FirebaseException catch (e) {
    if (e.code == 'unavailable' || e.code == 'network-request-failed') {
      try {
        return await run(const GetOptions(source: Source.cache));
      } on FirebaseException catch (cacheError) {
        throw RepositoryException.from(cacheError, context: context);
      }
    }
    throw RepositoryException.from(e, context: context);
  } catch (e) {
    throw RepositoryException.from(e, context: context);
  }
}

/// Wraps a Firestore write, normalising failures to [RepositoryException].
Future<T> runWrite<T>(
  Future<T> Function() run, {
  String? context,
}) async {
  try {
    return await run();
  } catch (e) {
    throw RepositoryException.from(e, context: context);
  }
}
