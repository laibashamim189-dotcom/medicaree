import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }
  Future<String?> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      throw Exception("Please fill in all fields.");
    }

    isLoading = true;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.enableNetwork();

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get()
          .timeout(const Duration(seconds: 15));

      if (userDoc.exists) {
        return userDoc.get('role') as String?;
      } else {
        return "USER_PROFILE_MISSING";
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw Exception("Please enter your email");
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}