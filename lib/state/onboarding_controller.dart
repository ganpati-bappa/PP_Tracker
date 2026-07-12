import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pp_tracker/models/onboarding/onboarding_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController extends ChangeNotifier {
  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;
  bool _shouldShowTour = true;
  bool get shouldShowTour => _shouldShowTour;
  bool _isInitialzed = false;
  bool get isInitialzed => _isInitialzed;

  Future<void> initialize() async {
    _isInitialzed = false;
    final prefs = await SharedPreferences.getInstance();
    _isCompleted = prefs.getBool('onboarding_completed') ?? false;
    _shouldShowTour = prefs.getBool('shouldShowTour') ?? true;
    notifyListeners();
    _isInitialzed = true;
  }

  Future<void> completeOnboarding({bool skipTour = false}) async {
    _isCompleted = true;
    _shouldShowTour = !skipTour;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('shouldShowTour', _shouldShowTour);

    notifyListeners();
  }

  Future<void> setTourStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shouldShowTour', status);
    _shouldShowTour = status;
    notifyListeners();
  }

  final List<OnboardingStep> _steps = [
    const OnboardingStep(
      id: 'welcome',
      title: 'Welcome to Petal',
      description: 'Your companion for cycle tracking and holistic wellness. Understand your body\'s natural rhythms.',
      imageUrl: 'assets/phases/Follicular.png',
      buttonText: 'Get Started',
    ),
    const OnboardingStep(
      id: 'library',
      title: 'Verified Health Library',
      description: 'Access professionally written articles, verified by experts, to help you navigate every phase of your cycle.',
      imageUrl: 'assets/phases/Fertile.png',
      buttonText: 'Next',
    ),
    const OnboardingStep(
      id: 'insights',
      title: 'Actionable Insights',
      description: 'Get personalized recommendations based on your unique cycle data. Sync your life with your hormones.',
      imageUrl: 'assets/phases/Luteal.png',
      buttonText: 'Start Your Journey',
    ),
  ];

  List<OnboardingStep> get steps => _steps;
}
