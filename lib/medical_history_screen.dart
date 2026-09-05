import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalHistoryScreen extends StatelessWidget {
  final String? patientId;
  const MedicalHistoryScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    // If a patientId is passed (from doctor view), use it. Otherwise use current user.
    final String? effectivePatientId = patientId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Medical History", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: effectivePatientId == null 
        ? const Center(child: Text("User not identified"))
        : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_history')
            .where('userId', isEqualTo: effectivePatientId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No history records found for this patient."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String title = data['title'] ?? 'Record';
              final String category = (data['category'] ?? 'General').toUpperCase();
              final String status = data['status'] ?? 'Marked';
              final String date = data['date'] ?? '';
              final String time = data['time'] ?? '';
              
              Color statusColor = (status == 'Taken' || status == 'Measured' || status == 'Completed' || status == 'Attended' || status == 'Done') 
                  ? Colors.green 
                  : Colors.red;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusColor == Colors.green ? Icons.check_circle_outline : Icons.cancel_outlined, color: statusColor),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$category\n$date at $time", style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
