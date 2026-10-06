import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUserModel(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      email: data['email'] ?? 'No Email',
      role: data['role'] ?? 'No Role',
    );
  }

  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Colors.blue;
      case 'patient':
        return Colors.green;
      case 'caregiver':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}