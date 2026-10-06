import 'dart:async';
import 'package:flutter/material.dart';
import '../models/splash_model.dart';

class SplashViewModel extends ChangeNotifier {
  Timer? _timer;
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void initialize(VoidCallback onNavigate) {
    // Subtle fade-in trigger
    Future.microtask(() {
      _isVisible = true;
      notifyListeners();
    });

    // 3 seconds timer for navigation callback
    _timer = Timer(const Duration(seconds: 3), () {
      onNavigate();
    });
  }

  NavigationTarget determineTargetScreen() {
    // Add logic here if you want to check FirebaseAuth auth state or Onboarding completed state
    return NavigationTarget.login;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}