import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/home.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';
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
  runApp(const PetalApp());
}

class PetalApp extends StatelessWidget {
  const PetalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Single instances shared across the app. Swap MockBlogRepository for a
    // Firestore implementation here and nothing above this line changes.
    final BlogRepository blogRepository = MockBlogRepository();

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserModel()),
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
