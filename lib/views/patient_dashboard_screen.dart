import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'medication_screen.dart';
import 'activity_screen.dart';
import 'measurement_tracker_screen.dart';
import 'measurement_screen.dart';
import 'login_screen.dart';
import 'medical_history_screen.dart';
import 'emergency_contacts_screen.dart';
import 'feedback_screen.dart';
import 'medical_directory_screen.dart';
import 'pharmacy_delivery_screen.dart';
import 'ai_chat_screen.dart';
import '../models/patient_dashboard_model.dart';
import '../view_models/patient_dashboard_view_model.dart';
import '../main.dart';

class PatientDashboard extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const PatientDashboard({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  late final PatientDashboardViewModel _viewModel;
  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _viewModel = PatientDashboardViewModel();
    _effectivePatientId = _viewModel.getEffectivePatientId(widget.patientId);
    _viewModel.listenForNotifications();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [
      DashboardHome(
        patientId: _effectivePatientId,
        isReadOnly: widget.isReadOnly,
        viewModel: _viewModel,
      ),
      MeasurementTrackerScreen(
        patientId: _effectivePatientId,
        isReadOnly: widget.isReadOnly,
      ),
      PharmacyDeliveryScreen(
        onBack: () => _viewModel.setSelectedIndex(0),
        isReadOnly: widget.isReadOnly,
        patientId: _effectivePatientId,
      ),
      AiChatScreen(
        onBack: () => _viewModel.setSelectedIndex(0),
        isReadOnly: false,
      ),
      ProfileScreen(
        patientId: _effectivePatientId,
        viewModel: _viewModel,
        onBack: () => _viewModel.setSelectedIndex(0),
        isReadOnly: widget.isReadOnly,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final screens = _buildScreens();

        return Scaffold(
          body: IndexedStack(
            index: _viewModel.selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _viewModel.selectedIndex,
            selectedItemColor: const Color(0xFF1565C0),
            unselectedItemColor: Colors.grey,
            onTap: _viewModel.setSelectedIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Tracker"),
              BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy), label: "Pharmacy"),
              BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "Chatbot"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        );
      },
    );
  }
}

class DashboardHome extends StatelessWidget {
  final String patientId;
  final bool isReadOnly;
  final PatientDashboardViewModel viewModel;

  const DashboardHome({
    super.key,
    required this.patientId,
    required this.viewModel,
    this.isReadOnly = false,
  });

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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 35),
                const SizedBox(height: 15),
                const Text("Hello,", style: TextStyle(color: Colors.white70, fontSize: 18)),
                StreamBuilder<PatientUserProfile>(
                  stream: viewModel.getUserProfileStream(patientId),
                  builder: (context, snapshot) {
                    final name = snapshot.hasData ? snapshot.data!.name : "Medicare";
                    return Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final String patientId;
  final PatientDashboardViewModel viewModel;
  final VoidCallback? onBack;
  final bool isReadOnly;

  const ProfileScreen({
    super.key,
    required this.patientId,
    required this.viewModel,
    this.onBack,
    this.isReadOnly = false,
  });

  static const Color brandBlue = Color(0xFF1565C0);

  void _showImageSourceDialog(BuildContext context, String? currentImageUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: brandBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Profile picture",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue),
                    ),
                  ),
                  currentImageUrl != null
                      ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmRemovePhoto(context);
                    },
                  )
                      : const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: brandBlue),
              title: const Text("Gallery", style: TextStyle(color: brandBlue, fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final res = await viewModel.pickAndUploadProfileImage(patientId, ImageSource.gallery);
                if (res != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: brandBlue),
              title: const Text("Camera", style: TextStyle(color: brandBlue, fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                final res = await viewModel.pickAndUploadProfileImage(patientId, ImageSource.camera);
                if (res != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
                }
              },
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  void _confirmRemovePhoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text("Remove profile picture?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await viewModel.removeProfilePhoto(patientId);
              if (res != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
              }
            },
            child: const Text("Remove", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwnDashboard = viewModel.isOwnDashboard(patientId);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
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
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        children: [
                          Text(
                            "My Profile",
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<PatientUserProfile>(
                      stream: viewModel.getUserProfileStream(patientId),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        final name = profile?.name ?? "User Profile";
                        final email = profile?.email ?? "Managing your health";
                        final profileImageUrl = profile?.profileImageUrl;

                        return Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                                  child: profileImageUrl == null
                                      ? const Icon(Icons.person, size: 65, color: Colors.white)
                                      : null,
                                ),
                                if (viewModel.isUploadingImage)
                                  const Positioned.fill(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                if (!isReadOnly)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _showImageSourceDialog(context, profileImageUrl),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: brandBlue,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                        ),
                                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
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
                    const Text(
                      "Account Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                    ),
                    const SizedBox(height: 15),
                    _profileOption(context, Icons.history_edu, "Medical History", brandBlue, MedicalHistoryScreen(patientId: patientId)),
                    _profileOption(context, Icons.emergency_outlined, "Emergency Contacts", Colors.redAccent, EmergencyContactsScreen(patientId: patientId, isReadOnly: isReadOnly)),
                    _profileOption(context, Icons.chat_bubble_outline, "Send Feedback", Colors.orangeAccent, const FeedbackScreen()),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (!isOwnDashboard) {
                      Navigator.pop(context);
                    } else {
                      await viewModel.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    }
                  },
                  icon: Icon(isOwnDashboard ? Icons.logout : Icons.arrow_back, color: Colors.red),
                  label: Text(
                    isOwnDashboard ? "LOG OUT" : "BACK TO PORTAL",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
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
      },
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
