import 'package:flutter/material.dart';

// Credentials for Admin Login
class AdminCredentials {
  final String email;
  final String password;

  AdminCredentials({
    required this.email,
    required this.password,
  });
}

// Result of Login attempt
class LoginResult {
  final bool isSuccess;
  final String? errorMessage;

  LoginResult({
    required this.isSuccess,
    this.errorMessage,
  });
}

// Items shown in Admin Dashboard
class AdminMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget targetScreen;

  AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.targetScreen,
  });
}

// Alert for new verification requests
class NewRequestAlert {
  final String applicantName;
  final DateTime updatedAt;

  NewRequestAlert({
    required this.applicantName,
    required this.updatedAt,
  });
}
