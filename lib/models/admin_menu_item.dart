import 'package:flutter/material.dart';

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

class NewRequestAlert {
  final String applicantName;
  final DateTime updatedAt;

  NewRequestAlert({
    required this.applicantName,
    required this.updatedAt,
  });
}