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
    _timer = Timer(const Duration(seconds: 3), () {
      onNavigate();
    });
  }

  NavigationTarget determineTargetScreen() {
    return NavigationTarget.login;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}