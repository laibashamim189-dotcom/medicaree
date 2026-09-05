import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_screen.dart';

class AppointmentListWidget extends StatelessWidget {
  final Color primaryBlue;

  const AppointmentListWidget({super.key, required this.primaryBlue});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("No appointments found", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            
            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.transparent,
                child: const Icon(Icons.delete, color: Colors.grey),
              ),
              onDismissed: (direction) {
                FirebaseFirestore.instance.collection('appointments').doc(doc.id).delete();
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      child: Icon(Icons.person, color: primaryBlue, size: 30),
                    ),
                    title: Text(
                      data['doctorName'] ?? "Doctor",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          data['specialty'] ?? "Medical Consultation",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: primaryBlue),
                            const SizedBox(width: 5),
                            Text(
                              data['date'] ?? "No Date",
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 15),
                            Icon(Icons.access_time, size: 16, color: primaryBlue),
                            const SizedBox(width: 5),
                            Text(
                              data['time'] ?? "No Time",
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
