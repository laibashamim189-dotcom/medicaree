import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'admin_license_approval_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_users_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final Color darkBlue = const Color(0xFF1A233A);
  final DateTime _panelOpenTime = DateTime.now(); // Record when Admin opened the dashboard

  @override
  void initState() {
    super.initState();
    _listenForIncomingRequests();
  }

  void _listenForIncomingRequests() {
    FirebaseFirestore.instance
        .collection('users')
        .where('licenseStatus', isEqualTo: 'PENDING')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          
          // Only show notification if the request was updated AFTER the Admin opened this panel
          Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
          if (updatedAt != null && updatedAt.toDate().isAfter(_panelOpenTime)) {
            if (mounted) {
              _showNewRequestAlert(data['name'] ?? 'A professional');
            }
          }
        }
      }
    });
  }

  void _showNewRequestAlert(String name) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Remove existing one first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "New License Request: $name",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: "VIEW",
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide immediately on click
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminLicenseApprovalScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: darkBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.admin_panel_settings, size: 80, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Welcome, Administrator",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "System Management & Security",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuCard(
                    context,
                    title: "Licenses Verification",
                    subtitle: "Approve or Reject medical licenses",
                    icon: Icons.verified_user,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminLicenseApprovalScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildMenuCard(
                    context,
                    title: "User Feedback",
                    subtitle: "View feedback from patients and caregivers",
                    icon: Icons.feedback,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminFeedbackScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildMenuCard(
                    context,
                    title: "Registered Users",
                    subtitle: "View all registered users and their roles",
                    icon: Icons.people,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
