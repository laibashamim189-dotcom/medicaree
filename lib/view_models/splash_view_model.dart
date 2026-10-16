import 'dart:async';
import 'package:flutter/material.dart';

enum NavigationTarget {
  login,
  home,
}

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
    // You can add logic here to check if user is already logged in
    return NavigationTarget.login;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
