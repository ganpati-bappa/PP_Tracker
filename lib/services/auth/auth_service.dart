// Provider-agnostic authentication contract.
//
// The app depends only on this interface, never on `firebase_auth` directly.
// FirebaseAuthService is the current implementation; a different backend
// (or a purely-local "guest" flow) can implement the same surface without any
// changes above this line.

/// A minimal snapshot of the raw authenticated identity, decoupled from any
/// SDK type. Mapped into the richer [AppUser] profile by the user repository.
class AuthAccount {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isAnonymous;

  /// 'google', 'password', 'anonymous', … — how this identity signed in.
  final String provider;

  const AuthAccount({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isAnonymous = false,
    this.provider = 'unknown',
  });
}

/// Raised when sign-in fails. [cancelled] distinguishes a user-aborted flow
/// (dismissed the Google chooser) from a genuine error, so the UI can stay
/// quiet in that case.
class AuthException implements Exception {
  final String message;
  final bool cancelled;
  const AuthException(this.message, {this.cancelled = false});

  @override
  String toString() => 'AuthException: $message';
}

abstract class AuthService {
  /// Emits the current account (or null when signed out) and every change.
  Stream<AuthAccount?> authStateChanges();

  /// The currently signed-in account, if any (synchronous best-effort).
  AuthAccount? get currentAccount;

  /// Interactive Google sign-in. Throws [AuthException] on failure/cancel.
  Future<AuthAccount> signInWithGoogle();

  Future<void> signOut();
}
