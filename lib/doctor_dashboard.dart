import 'package:flutter/material.dart';
import 'doctor_review_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  // Mock data of patients who booked appointments via disease search
  final List<Map<String, String>> pendingRequests = const [
    {'name': 'John Doe', 'id': 'P-101', 'condition': 'Diabetes - High Sugar'},
    {'name': 'Jane Smith', 'id': 'P-105', 'condition': 'Hypertension - BP 160/100'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Portal - Requests"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              title: Text(pendingRequests[index]['name']!),
              subtitle: Text("Complaint: ${pendingRequests[index]['condition']}"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorReviewScreen(
                        patientName: pendingRequests[index]['name']!,
                        patientCondition: pendingRequests[index]['condition']!,
                      ),
                    ),
                  );
                },
                child: const Text("Accept & Review", style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}