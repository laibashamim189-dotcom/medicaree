import 'package:flutter/material.dart';
import 'caregiver_request_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  bool isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Incoming Patient Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // The Request Card
            if (!isAccepted)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person_pin, color: Colors.white)),
                      title: Text("Patient: Ahmed Ali", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Wants to add you as: Professional Nurse"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text("Decline", style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              setState(() => isAccepted = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Request Accepted! You are now linked.")),
                              );
                            },
                            child: const Text("Accept Request", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            else
              const Center(
                child: Text("Successfully linked to Patient: Ahmed Ali", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),

      // Fixed Request Button at the bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CaregiverRequestScreen()),
            );
          },
          icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
          label: const Text(
            "SEND NEW REQUEST",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
