import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medication_screen.dart';
import 'measurement_screen.dart';
import 'activity_screen.dart';
import 'doctor_search_screen.dart';
import 'appointment_screen.dart';
import 'measurement_tracker.dart';
import 'login_screen.dart';
import 'medical_history_screen.dart';
import 'emergency_contacts_screen.dart';
import 'feedback_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const HealthTrackerScreen(),
    const ChatbotScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Reminders"),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: "Tracker"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "AI Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// --- SCREEN 1: DASHBOARD HOME ---
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield, color: Colors.white, size: 35),
                SizedBox(height: 15),
                Text("Hello,", style: TextStyle(color: Colors.white70, fontSize: 18)),
                Text("medicare", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                Text("Let's manage your daily health routine.", style: TextStyle(color: Colors.white60)),
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
                  _gridCard(context, "Medications", "Pills & Drops", Icons.local_pharmacy, Colors.blue, const MedicationScreen()),
                  _gridCard(context, "Measurements", "Weight & BP", Icons.straighten, Colors.cyan, const MeasurementTracker()),
                  _gridCard(context, "Activities", "Walking & Water", Icons.directions_run, Colors.teal, const ActivityScreen()),
                  _gridCard(context, "Chatbot", "AI Assistant", Icons.chat_bubble_outline, Colors.indigo, const ChatbotScreen()),
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
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 2: HEALTH TRACKER ---
class HealthTrackerScreen extends StatefulWidget {
  const HealthTrackerScreen({super.key});
  @override
  State<HealthTrackerScreen> createState() => _HealthTrackerScreenState();
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  final TextEditingController _valController = TextEditingController();
  String selectedCategory = 'Blood Pressure';
  String unit = 'mmHg';

  final List<Map<String, dynamic>> _history = [
    {'type': 'Blood Pressure', 'value': '120/80', 'unit': 'mmHg', 'date': '2026-05-15', 'time': '10:30 AM'},
    {'type': 'Blood Sugar', 'value': '95', 'unit': 'mg/dL', 'date': '2026-05-15', 'time': '08:00 AM'},
  ];

  void _addMeasurement() {
    if (_valController.text.isNotEmpty) {
      setState(() {
        _history.insert(0, {
          'type': selectedCategory,
          'value': _valController.text,
          'unit': unit,
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'time': DateFormat('hh:mm a').format(DateTime.now()),
        });
        _valController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Health Tracker", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.blue[800],
                  value: selectedCategory,
                  style: const TextStyle(color: Colors.white),
                  items: ['Blood Pressure', 'Blood Sugar', 'Body Weight']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCategory = val!;
                      if (val == 'Blood Pressure') unit = 'mmHg';
                      else if (val == 'Blood Sugar') unit = 'mg/dL';
                      else unit = 'kg';
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Category",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _valController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Enter Value ($unit)",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Add to History", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 25, left: 20, bottom: 10),
            child: Align(alignment: Alignment.centerLeft, child: Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.history, color: Color(0xFF1565C0))),
                    title: Text("${item['value']} ${item['unit']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${item['type']} • ${item['date']}"),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- SCREEN 3: AI CHATBOT SCREEN ---
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hello! I am your Medicare AI. How can I help you today?", "isUser": false},
  ];

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;
    setState(() {
      _messages.add({"text": _messageController.text, "isUser": true});
      _messages.add({"text": "I'm analyzing your health query...", "isUser": false});
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("AI Health Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg['isUser'] ? const Color(0xFF1565C0) : Colors.white,
                      borderRadius: BorderRadius.circular(15).copyWith(
                        bottomRight: msg['isUser'] ? const Radius.circular(0) : const Radius.circular(15),
                        bottomLeft: msg['isUser'] ? const Radius.circular(15) : const Radius.circular(0),
                      ),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: Text(msg['text'], style: TextStyle(color: msg['isUser'] ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your health concern...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      fillColor: Colors.grey[200], filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Color(0xFF1565C0))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- SCREEN 4: PROFILE SCREEN ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text("My Profile", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                const CircleAvatar(radius: 50, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 60, color: Colors.white)),
                const SizedBox(height: 15),
                const Text("New User", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("medicare@gmail.com", style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                _profileOption(context, Icons.history_edu, "Medical History", Colors.blue, const MedicalHistoryScreen()),
                _profileOption(context, Icons.emergency_outlined, "Emergency Contacts", Colors.redAccent, const EmergencyContactsScreen()),
                _profileOption(context, Icons.chat_bubble_outline, "Send Feedback", Colors.orangeAccent, const FeedbackScreen()),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: OutlinedButton.icon(
              onPressed: () {
                // NAVIGATION LOGIC FOR LOGOUT
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("LOG OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      ),
    );
  }
}
