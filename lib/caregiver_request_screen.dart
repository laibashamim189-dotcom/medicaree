import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CaregiverRequestsViewScreen extends StatelessWidget {
  const CaregiverRequestsViewScreen({Key? key}) : super(key: key);

  // Accept request function
  Future<void> _acceptRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('caregiver_requests')
        .doc(requestId)
        .update({
      'status': 'accepted', // Status changes to 'accepted'
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject request function
  Future<void> _rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('caregiver_requests')
        .doc(requestId)
        .update({
      'status': 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentCaregiverEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Patient Requests'),
        backgroundColor: const Color(0xFF4B9F90),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Caregiver ko apni email wali saari requests yahan milengi
        stream: FirebaseFirestore.instance
            .collection('caregiver_requests')
            .where('caregiverEmail', isEqualTo: currentCaregiverEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending requests found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String docId = doc.id;
              final String status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Patient: ${data['patientName'] ?? 'Unknown'}"),
                  subtitle: Text("Relationship: ${data['relationship']}\nStatus: $status"),
                  trailing: status == 'pending'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _acceptRequest(docId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _rejectRequest(docId),
                      ),
                    ],
                  )
                      : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: status == 'accepted'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: status == 'accepted'
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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