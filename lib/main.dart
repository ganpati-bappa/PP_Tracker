import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/config/app_config.dart';
import 'package:pp_tracker/home.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';
import 'package:pp_tracker/repositories/firestore_blog_repository.dart';
import 'package:pp_tracker/repositories/firestore_seeder.dart';
import 'package:pp_tracker/repositories/cycle_profile_store.dart';
import 'package:pp_tracker/repositories/firestore_user_repository.dart';
import 'package:pp_tracker/repositories/local_user_repository.dart';
import 'package:pp_tracker/repositories/mock_blog_repository.dart';
import 'package:pp_tracker/services/auth/firebase_auth_service.dart';
import 'package:pp_tracker/state/auth_controller.dart';
import 'package:pp_tracker/state/blog_controller.dart';
import 'package:pp_tracker/state/onboarding_controller.dart';
import 'package:pp_tracker/pages/auth/login_screen.dart';
import 'package:pp_tracker/pages/onboarding/onboarding_screen.dart';
import 'package:pp_tracker/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (AppConfig.usesFirestore) {
    // Enable Firestore's on-device cache so reads work offline and writes queue
    // and replay automatically when connectivity returns.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // Debug-only: give a fresh project browsable content. No-ops once seeded,
    // and never runs in release builds.
    if (kDebugMode) {
      try {
        await FirestoreSeeder().seedIfEmpty();
      } catch (e) {
        debugPrint('Blog seed skipped: $e');
      }
    }
  }

  runApp(const PetalApp());
}

class PetalApp extends StatelessWidget {
  const PetalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The single seam that selects the blog backend. Everything above the
    // BlogRepository interface is identical for mock and Firestore.
    final BlogRepository blogRepository = AppConfig.usesFirestore
        ? FirestoreBlogRepository()
        : MockBlogRepository();

    return ChangeNotifierProvider(
      create: (_) => AuthController(
        authService: FirebaseAuthService(),
        remoteUsers: FirestoreUserRepository(),
        localUsers: LocalUserRepository(),
      )..start(),
      child: MaterialApp(
        title: 'Petal — Cycle & Wellness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _AuthGate(blogRepository: blogRepository),
      ),
    );
  }
}

/// Routes between splash, login and the authenticated app based on auth state.
class _AuthGate extends StatelessWidget {
  final BlogRepository blogRepository;
  const _AuthGate({required this.blogRepository});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _Splash();
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return _AuthenticatedApp(
          key: ValueKey(auth.currentUser!.id),
          user: auth.currentUser!,
          blogRepository: blogRepository,
        );
    }
  }
}

/// Provides the per-user state (cycle data, onboarding, blogs) once signed in.
/// Keyed by user id so switching accounts rebuilds fresh state.
class _AuthenticatedApp extends StatelessWidget {
  final AppUser user;
  final BlogRepository blogRepository;
  const _AuthenticatedApp({
    super.key,
    required this.user,
    required this.blogRepository,
  });

  @override
  Widget build(BuildContext context) {
    // Guests live entirely in SharedPreferences; signed-in users also mirror
    // their (private) cycle profile to Firestore for cross-device sync.
    final useRemote = !user.isAnonymous && AppConfig.usesFirestore;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final model = UserModel(
              uid: user.id,
              profileStore: CycleProfileStore(useRemote: useRemote),
            );
            // Personalise the greeting from the signed-in identity.
            final name = user.displayName.trim();
            if (name.isNotEmpty && name.toLowerCase() != 'guest') {
              model.preferences.name = name;
            }
            return model;
          },
        ),
        ChangeNotifierProvider(create: (_) {
          final controller = OnboardingController();
          controller.initialize();
          return controller;
        }),
        ChangeNotifierProvider(
          create: (_) => BlogController(blogRepository, currentUser: user),
        ),
      ],
      child: Consumer<OnboardingController>(
        builder: (context, onboarding, _) {
          if (!onboarding.isInitialzed) {
            return const _Splash();
          } else {
            return (onboarding.isCompleted)
                ? const HomePage()
                : const OnboardingScreen();
          }
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
    );
  }
}
