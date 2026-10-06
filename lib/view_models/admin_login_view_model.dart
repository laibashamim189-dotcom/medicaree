import 'package:flutter/material.dart';
import '../models/admin_credentials.dart';

class AdminLoginViewModel extends ChangeNotifier {
  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<LoginResult> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Small delay to simulate authentication process
    await Future.delayed(const Duration(milliseconds: 300));

    _isLoading = false;
    notifyListeners();

    // Hardcoded Admin Credentials Check
    if (email == "admin@medicare.com" && password == "admin786") {
      return LoginResult(isSuccess: true);
    } else {
      return LoginResult(
        isSuccess: false,
        errorMessage: "Invalid Admin Credentials",
      );
    }
  }
}