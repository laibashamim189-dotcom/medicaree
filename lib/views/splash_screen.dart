import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../models/splash_model.dart';
import '../view_models/splash_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashViewModel _viewModel;
  final Color brandBlue = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = SplashViewModel();
    _viewModel.initialize(_handleNavigation);
  }

  void _handleNavigation() {
    if (!mounted) return;

    final target = _viewModel.determineTargetScreen();

    Widget destinationScreen;
    switch (target) {
      case NavigationTarget.login:
        destinationScreen = const LoginScreen();
        break;
      case NavigationTarget.home:
        destinationScreen = const LoginScreen(); // Replace with HomeScreen if needed
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1000),
              opacity: _viewModel.isVisible ? 1.0 : 0.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: brandBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: 90,
                      color: brandBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  Text(
                    "Medicare",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: brandBlue,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Smart Healthcare Reminder",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Loading Indicator
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(brandBlue),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
