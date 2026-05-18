import 'package:flutter/material.dart';
import 'patient_dashboard.dart';
import 'medication_screen.dart';
import 'measurement_screen.dart';
import 'activity_screen.dart';
import 'appointment_screen.dart';
import 'caregiver_request_screen.dart'; 

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final List<Map<String, String>> allDoctors = [
    {'name': 'Dr. Sarah Ahmed', 'specialty': 'Cardiologist', 'disease': 'Heart, BP, Chest Pain'},
    {'name': 'Dr. Ali Raza', 'specialty': 'General Physician', 'disease': 'Flu, Fever, Headache'},
    {'name': 'Dr. Maria Khan', 'specialty': 'Endocrinologist', 'disease': 'Diabetes, Sugar, Thyroid'},
    {'name': 'Dr. Usman Peerzada', 'specialty': 'Orthopedic', 'disease': 'Bone, Joint Pain, Fracture'},
  ];

  List<Map<String, String>> suggestedDoctors = [];
  final TextEditingController _diseaseController = TextEditingController();

  void _searchDoctor(String query) {
    if (query.isEmpty) {
      setState(() => suggestedDoctors = []);
      return;
    }
    setState(() {
      suggestedDoctors = allDoctors.where((doc) {
        return doc['disease']!.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find a Doctor"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => PatientDashboard()), // Removed const to fix compilation error
                  (route) => false,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "What are you feeling?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _diseaseController,
              onChanged: _searchDoctor,
              decoration: InputDecoration(
                hintText: "Enter disease name (e.g. BP, Heart)",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.blue.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Suggested Specialists:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestedDoctors.isEmpty ? 0 : suggestedDoctors.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(suggestedDoctors[index]['name']!),
                    subtitle: Text(suggestedDoctors[index]['specialty']!),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () => _showNavigationMenu(suggestedDoctors[index]['name']!),
                      child: const Text("Book", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
            if (suggestedDoctors.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("Type a disease to see recommendations"),
              ),
          ],
        ),
      ),
    );
  }

  void _showNavigationMenu(String doctorName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Wrap( 
            children: [
              const Center(
                child: Text(
                  "Appointment Requested!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.blue),
                title: const Text("Go to Patient Dashboard"),
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PatientDashboard())), // Removed const
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.purple),
                title: const Text("Request a Caregiver"),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CaregiverRequestScreen())),
              ),

            ],
          ),
        );
      },
    );
  }
}
