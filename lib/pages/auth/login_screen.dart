import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/state/auth_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// Sign-in screen. Google is the primary path; "continue as guest" routes to
/// the local-only identity so the app is usable without an account.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const _Brand(),
                const Spacer(flex: 4),
                if (auth.errorMessage != null) ...[
                  _ErrorBanner(message: auth.errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _GoogleButton(
                  busy: auth.isBusy,
                  onPressed: auth.isBusy
                      ? null
                      : () => context.read<AuthController>().signInWithGoogle(),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: auth.isBusy
                      ? null
                      : () => context.read<AuthController>().continueAsGuest(),
                  child: Text(
                    'Continue without an account',
                    style: AppText.label.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDeep],
            ),
            shape: BoxShape.circle,
            boxShadow: AppShadows.lifted,
          ),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Petal', style: AppText.display),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your companion for cycle\ntracking & holistic wellness',
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  const _GoogleButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.divider, width: 1.4),
              boxShadow: AppShadows.soft,
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _GoogleG(),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Continue with Google', style: AppText.bodyStrong),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A lightweight rendition of the Google "G" mark for the sign-in button.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleGPainter()));
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final stroke = size.width * 0.26;
    final rect = Rect.fromCircle(center: c, radius: r - stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four brand-coloured arcs approximating the Google G.
    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    void arc(double startDeg, double sweepDeg, Color color) {
      paint.color = color;
      canvas.drawArc(rect, _rad(startDeg), _rad(sweepDeg), false, paint);
    }

    arc(-20, -70, blue); // right/top-right
    arc(-90, -110, green); // top-left
    arc(-200, -60, yellow); // left
    arc(90, 70, red); // bottom

    // The horizontal bar of the G.
    final bar = Paint()..color = blue;
    canvas.drawRect(Rect.fromLTWH(c.dx, c.dy - stroke / 2, r - stroke / 2, stroke), bar);
  }

  double _rad(double deg) => deg * 3.1415926535 / 180.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alpha(AppColors.danger, 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.alpha(AppColors.danger, 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppText.label.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
