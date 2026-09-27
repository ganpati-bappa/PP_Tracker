import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/pages/onboarding/cycle_setup_screen.dart';
import 'package:pp_tracker/state/onboarding_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Once the intro slides are done we swap the whole screen over to the cycle
  /// setup form (the final onboarding step, shown before the guided tour).
  bool _showSetup = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Applies-and-persists happens inside [CycleSetupView]; here we just flip the
  /// onboarding-complete flag so the app routes on to the home + guided tour.
  Future<void> _finishOnboarding() async {
    await context.read<OnboardingController>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final steps = controller.steps;

    if (_showSetup) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AppBackground(
          child: CycleSetupView(onComplete: _finishOnboarding),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      step.imageUrl,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: AppText.h1.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    steps.length,
                    (index) => AnimatedContainer(
                      duration: AppDuration.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      if (_currentPage < steps.length - 1) {
                        _pageController.nextPage(
                          duration: AppDuration.normal,
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Last intro slide -> collect the cycle metrics.
                        setState(() => _showSetup = true);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Text(
                      steps[_currentPage].buttonText ?? 'Next',
                      style: AppText.bodyStrong.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                if (_currentPage < steps.length - 1)
                  TextButton(
                    onPressed: () {
                      // Skip the intro, but still collect the cycle metrics —
                      // they're pre-filled with defaults, so it's a one-tap
                      // finish for anyone in a hurry.
                      setState(() => _showSetup = true);
                    },
                    child: Text(
                      'Skip',
                      style: AppText.label.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
