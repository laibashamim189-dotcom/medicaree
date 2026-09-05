import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication_screen.dart';
import 'activity_screen.dart';
import 'measurement_tracker.dart';
import 'measurement_screen.dart';
import 'login_screen.dart';
import 'medical_history_screen.dart';
import 'emergency_contacts_screen.dart';
import 'feedback_screen.dart';
import 'medical_directory_screen.dart';
import 'pharmacyDelivery_screen.dart';
import 'AiChatScreen.dart';

class PatientDashboard extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const PatientDashboard({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  late String _effectivePatientId;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // If patientId is passed (from Doctor), use it. Otherwise, use logged-in user.
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    _updateScreens();
  }

  void _updateScreens() {
    _screens = [
      DashboardHome(patientId: _effectivePatientId, isReadOnly: widget.isReadOnly),
      MeasurementTrackerScreen(patientId: _effectivePatientId, isReadOnly: widget.isReadOnly),
      PharmacyDeliveryScreen(
        onBack: () => setState(() => _selectedIndex = 0),
        isReadOnly: widget.isReadOnly,
        patientId: _effectivePatientId,
      ),
      AiChatScreen(
        onBack: () => setState(() => _selectedIndex = 0),
        isReadOnly: false, // Doctors and Patients can both chat; never read-only.
      ),
      ProfileScreen(
        patientId: _effectivePatientId,
        onBack: () => setState(() => _selectedIndex = 0),
        isReadOnly: widget.isReadOnly,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _updateScreens();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Tracker"),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy), label: "Pharmacy"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "Chatbot"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// --- SCREEN 1: DASHBOARD HOME ---
class DashboardHome extends StatelessWidget {
  final String patientId;
  final bool isReadOnly;
  const DashboardHome({super.key, required this.patientId, this.isReadOnly = false});

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 40),
            decoration: const BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 35),
                const SizedBox(height: 15),
                const Text("Hello,", style: TextStyle(color: Colors.white70, fontSize: 18)),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(patientId).snapshots(),
                  builder: (context, snapshot) {
                    String name = "Medicare";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      try {
                        name = snapshot.data!.get('name') ?? "Medicare";
                      } catch (e) {
                        name = "Medicare";
                      }
                    }
                    return Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const Text("Let's manage your daily health routine.", style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _gridCard(context, "Medications", "Pills & Drops", Icons.medication, brandBlue, MedicationScreen(patientId: patientId, isReadOnly: isReadOnly)),
                  _gridCard(context, "Measurements", "Weight & BP", Icons.straighten, Colors.cyan, MeasurementScreen(patientId: patientId, isReadOnly: isReadOnly)),
                  _gridCard(context, "Activities", "Walking & Water", Icons.directions_run, Colors.teal, ActivityScreen(patientId: patientId, isReadOnly: isReadOnly)),
                  _gridCard(context, "Medical Professional", "", Icons.assignment_ind, Colors.orange, MedicalDirectoryScreen(patientId: patientId, isReadOnly: isReadOnly)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridCard(BuildContext context, String title, String sub, IconData icon, Color color, Widget dest) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => dest)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 5: PROFILE SCREEN ---
class ProfileScreen extends StatelessWidget {
  final String patientId;
  final VoidCallback? onBack;
  final bool isReadOnly;
  const ProfileScreen({super.key, required this.patientId, this.onBack, this.isReadOnly = false});

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 40),
            decoration: const BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: onBack,
                        ),
                      const Text(
                        "My Profile",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 15),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(patientId).snapshots(),
                  builder: (context, snapshot) {
                    String name = "User Profile";
                    String email = "Managing your health";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      try {
                        name = snapshot.data!.get('name') ?? "User Profile";
                        email = snapshot.data!.get('email') ?? "Managing your health";
                      } catch (e) {
                        debugPrint("Error fetching user profile: $e");
                      }
                    }
                    return Column(
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(email, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Account Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                const SizedBox(height: 15),
                _profileOption(context, Icons.history_edu, "Medical History", brandBlue, MedicalHistoryScreen(patientId: patientId)),
                _profileOption(context, Icons.emergency_outlined, "Emergency Contacts", Colors.redAccent, EmergencyContactsScreen(patientId: patientId, isReadOnly: isReadOnly)),
                if (!isReadOnly)
                   _profileOption(context, Icons.chat_bubble_outline, "Send Feedback", Colors.orangeAccent, const FeedbackScreen()),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: OutlinedButton.icon(
              onPressed: () {
                if (isReadOnly) {
                  Navigator.pop(context);
                } else {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: Icon(isReadOnly ? Icons.arrow_back : Icons.logout, color: Colors.red),
              label: Text(isReadOnly ? "BACK TO PORTAL" : "LOG OUT", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _profileOption(BuildContext context, IconData icon, String title, Color color, Widget destination) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      ),
    );
  }
}
