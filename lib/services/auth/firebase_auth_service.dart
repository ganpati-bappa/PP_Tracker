import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pp_tracker/services/auth/auth_service.dart';

const String _serverClientId = "322486957441-bv75ouu9630kbqe4auddkplej8ptjebp.apps.googleusercontent.com";
/// Firebase-backed [AuthService] using Google Sign-In.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              // The OAuth "web" client (oauth_client type 3 in
              // google-services.json, a.k.a. default_web_client_id). Supplying
              // it makes Google return an ID token Firebase can exchange for a
              // credential on Android. It's a project-level client, so it stays
              // the same across apps in the petal-a1290 project — only update
              // this if you move to a different Firebase project.
              serverClientId: _serverClientId,
            );

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AuthAccount?> authStateChanges() =>
      _auth.authStateChanges().map(_map);

  @override
  AuthAccount? get currentAccount => _map(_auth.currentUser);

  @override
  Future<AuthAccount> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Sign-in cancelled.', cancelled: true);
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final account = _map(result.user);
      if (account == null) {
        throw const AuthException('Sign-in failed. Please try again.');
      }
      return account;
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Authentication failed (${e.code}).');
    } catch (e) {
      throw AuthException('Could not sign in with Google. $e');
    }
  }

  @override
  Future<void> signOut() async {
    // Sign out of Google too so the account chooser reappears next time.
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }

  /// Maps a Firebase user to our provider-agnostic [AuthAccount].
  AuthAccount? _map(fb.User? user) {
    if (user == null) return null;
    final provider = user.isAnonymous
        ? 'anonymous'
        : (user.providerData.isNotEmpty
            ? _friendlyProvider(user.providerData.first.providerId)
            : 'unknown');
    return AuthAccount(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      provider: provider,
    );
  }

  String _friendlyProvider(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'google';
      case 'password':
        return 'password';
      case 'apple.com':
        return 'apple';
      default:
        return providerId;
    }
  }
}
