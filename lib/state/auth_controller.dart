import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/repositories/user_repository.dart';
import 'package:pp_tracker/services/auth/auth_service.dart';

enum AuthStatus {
  /// Before the first auth event — show a splash.
  unknown,
  signedOut,
  authenticated,
}

/// Owns the app's authentication state and the signed-in [AppUser] profile.
///
/// It reconciles two identity sources behind one API:
///   • Firebase (Google) users, whose profile lives in [_remoteUsers]
///     (Firestore `users` collection);
///   • local "guest" users, whose profile lives in [_localUsers].
///
/// [users] returns the repository backing the *current* identity, so callers
/// (blog authoring, profile edits) persist to the right place automatically.
/// Adding a real local DB later is just a new [UserRepository] passed in as
/// [_localUsers] — nothing here changes.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    required UserRepository remoteUsers,
    required UserRepository localUsers,
  })  : _auth = authService,
        _remoteUsers = remoteUsers,
        _localUsers = localUsers;

  final AuthService _auth;
  final UserRepository _remoteUsers;
  final UserRepository _localUsers;

  StreamSubscription<AuthAccount?>? _sub;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  bool isBusy = false;
  String? errorMessage;
  bool _isGuest = false;

  bool get isSignedIn => currentUser != null;
  bool get isGuest => _isGuest;

  /// The user store backing the current identity. Use this everywhere you need
  /// to read/write the profile or bump activity counters.
  UserRepository get users => _isGuest ? _localUsers : _remoteUsers;

  /// Begins listening to auth changes. Call once at startup.
  void start() {
    _sub = _auth.authStateChanges().listen(_onAccountChanged);
  }

  Future<void> _onAccountChanged(AuthAccount? account) async {
    if (account == null) {
      // A signed-out Firebase stream must not disturb an active local guest.
      if (_isGuest) return;
      currentUser = null;
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    _isGuest = false;
    await _loadProfile(account, _remoteUsers);
  }

  Future<void> _loadProfile(AuthAccount account, UserRepository repo) async {
    try {
      currentUser = await repo.upsertFromAuth(account);
    } catch (e) {
      // Offline / rules hiccup — fall back to an auth-derived profile so the
      // app is still usable; it'll reconcile on the next successful write.
      currentUser = AppUser(
        id: account.uid,
        displayName: account.displayName ?? account.email?.split('@').first ??
            'Friend',
        email: account.email,
        avatarUrl: account.photoUrl,
        authProvider: account.provider,
        isAnonymous: account.isAnonymous,
        joinedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      debugPrint('Profile load failed, using fallback: $e');
    }
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _setBusy(true);
    try {
      await _auth.signInWithGoogle();
      // _onAccountChanged will load the profile and flip status.
    } on AuthException catch (e) {
      if (!e.cancelled) errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Something went wrong signing in.';
    } finally {
      _setBusy(false);
    }
  }

  /// Signs in as a local-only guest. Backed by [_localUsers] today; the same
  /// path will use the on-device database once it's plugged in.
  Future<void> continueAsGuest() async {
    _setBusy(true);
    try {
      final guestId = 'guest_${DateTime.now().microsecondsSinceEpoch}';
      final account = AuthAccount(
        uid: guestId,
        displayName: 'Guest',
        isAnonymous: true,
        provider: 'anonymous',
      );
      _isGuest = true;
      await _loadProfile(account, _localUsers);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    _setBusy(true);
    try {
      if (_isGuest) {
        _isGuest = false;
        currentUser = null;
        status = AuthStatus.signedOut;
        notifyListeners();
      } else {
        await _auth.signOut();
        // _onAccountChanged(null) will clear state.
      }
    } finally {
      _setBusy(false);
    }
  }

  // ---- Activity hooks (keep the users doc counters in sync) ---------------
  Future<void> recordPostCreated() => _bump(users.incrementPostCount,
      (u) => u.copyWith(postCount: u.postCount + 1));

  Future<void> recordCommentCreated() => _bump(users.incrementCommentCount,
      (u) => u.copyWith(commentCount: u.commentCount + 1));

  Future<void> recordBookmarkChanged(bool added) => _bump(
        (id, [by = 1]) => users.incrementBookmarkCount(id, added ? 1 : -1),
        (u) => u.copyWith(
            bookmarkCount: (u.bookmarkCount + (added ? 1 : -1)).clamp(0, 1 << 31)),
      );

  Future<void> _bump(
    Future<void> Function(String id, [int by]) remote,
    AppUser Function(AppUser) optimistic,
  ) async {
    final user = currentUser;
    if (user == null) return;
    currentUser = optimistic(user);
    notifyListeners();
    try {
      await remote(user.id);
    } catch (_) {
      // Non-fatal; the counter is a convenience rollup.
    }
  }

  void _setBusy(bool value) {
    isBusy = value;
    if (value) errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
