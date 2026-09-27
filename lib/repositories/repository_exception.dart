import 'package:cloud_firestore/cloud_firestore.dart';

/// The kind of failure a repository call hit, so callers can branch (e.g. show
/// an offline banner vs. a hard error) without depending on `cloud_firestore`.
enum RepositoryErrorKind {
  /// Device is offline and the data wasn't available in the local cache.
  network,

  /// Firestore security rules rejected the operation.
  permissionDenied,

  /// The requested document/resource does not exist.
  notFound,

  /// Anything else (quota, internal, malformed data, …).
  unknown,
}

/// A backend-agnostic error raised by the repository layer.
///
/// The UI and controllers depend only on this type, never on
/// `FirebaseException`, so the persistence backend stays swappable and errors
/// stay presentable. Use [message] for user-facing copy and [kind] for logic.
class RepositoryException implements Exception {
  final RepositoryErrorKind kind;
  final String message;
  final Object? cause;

  const RepositoryException(
    this.kind,
    this.message, {
    this.cause,
  });

  bool get isNetwork => kind == RepositoryErrorKind.network;

  /// Maps a raw error (typically a [FirebaseException]) onto a friendly,
  /// classified [RepositoryException].
  factory RepositoryException.from(Object error, {String? context}) {
    if (error is RepositoryException) return error;

    if (error is FirebaseException) {
      final kind = switch (error.code) {
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
          RepositoryErrorKind.network,
        'permission-denied' => RepositoryErrorKind.permissionDenied,
        'not-found' => RepositoryErrorKind.notFound,
        _ => RepositoryErrorKind.unknown,
      };
      return RepositoryException(
        kind,
        _messageFor(kind, context),
        cause: error,
      );
    }

    return RepositoryException(
      RepositoryErrorKind.unknown,
      context == null
          ? 'Something went wrong. Please try again.'
          : 'Couldn\'t $context. Please try again.',
      cause: error,
    );
  }

  static String _messageFor(RepositoryErrorKind kind, String? context) {
    final suffix = context == null ? '' : ' while trying to $context';
    return switch (kind) {
      RepositoryErrorKind.network =>
        'You appear to be offline$suffix. We\'ll sync when you\'re back.',
      RepositoryErrorKind.permissionDenied =>
        'You don\'t have permission to do this$suffix.',
      RepositoryErrorKind.notFound => 'We couldn\'t find that$suffix.',
      RepositoryErrorKind.unknown =>
        'Something went wrong$suffix. Please try again.',
    };
  }

  @override
  String toString() => 'RepositoryException($kind): $message'
      '${cause == null ? '' : ' (cause: $cause)'}';
}
