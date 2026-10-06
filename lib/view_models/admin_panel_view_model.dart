import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_menu_item.dart';
import '../views/admin_license_approval_screen.dart';
import '../views/admin_feedback_screen.dart';
import '../views/admin_users_screen.dart';

class AdminPanelViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DateTime panelOpenTime = DateTime.now();

  // Menu Options Configuration
  List<AdminMenuItem> get menuItems => [
    AdminMenuItem(
      title: "Licenses Verification",
      subtitle: "Approve or Reject medical licenses",
      icon: Icons.verified_user,
      color: Colors.blueAccent,
      targetScreen: const AdminLicenseApprovalScreen(),
    ),
    AdminMenuItem(
      title: "User Feedback",
      subtitle: "View feedback from patients and caregivers",
      icon: Icons.feedback,
      color: Colors.orange,
      targetScreen: const AdminFeedbackScreen(),
    ),
    AdminMenuItem(
      title: "Registered Users",
      subtitle: "View all registered users and their roles",
      icon: Icons.people,
      color: Colors.green,
      targetScreen: const AdminUsersScreen(),
    ),
  ];

  // Stream for new pending requests created after panel launch
  Stream<NewRequestAlert?> get newLicenseAlertStream {
    return _firestore
        .collection('users')
        .where('licenseStatus', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          Timestamp? updatedAt = data['updatedAt'] as Timestamp?;

          if (updatedAt != null && updatedAt.toDate().isAfter(panelOpenTime)) {
            return NewRequestAlert(
              applicantName: data['name'] ?? 'A professional',
              updatedAt: updatedAt.toDate(),
            );
          }
        }
      }
      return null;
    });
  }

  // Handle Logout
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      debugPrint("Signout error: $e");
      return false;
    }
  }
}