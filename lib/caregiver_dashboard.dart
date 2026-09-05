import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'patient_dashboard.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Caregiver Dashboard", style: TextStyle(color: Colors.white)),
          backgroundColor: brandBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            },
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.mail_outline), text: "Incoming"),
              Tab(icon: Icon(Icons.people_outline), text: "Accepted"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('caregiver_requests')
              .where('caregiverEmail', isEqualTo: currentUser!.email)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No patient requests found"));
            }

            final allRequests = snapshot.data!.docs;
            final pendingRequests = allRequests.where((doc) => doc['status'] != 'accepted').toList();
            final acceptedRequests = allRequests.where((doc) => doc['status'] == 'accepted').toList();

            return TabBarView(
              children: [
                // --- TAB 1: INCOMING REQUESTS ---
                _buildIncomingList(pendingRequests),

                // --- TAB 2: ACCEPTED PATIENTS ---
                _buildAcceptedList(acceptedRequests),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIncomingList(List<QueryDocumentSnapshot> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text("No new incoming requests", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        var data = requests[index].data() as Map<String, dynamic>;
        return _buildPendingCard(requests[index].id, data);
      },
    );
  }

  Widget _buildAcceptedList(List<QueryDocumentSnapshot> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text("No accepted patients yet", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        var data = requests[index].data() as Map<String, dynamic>;
        return _buildAcceptedCard(data);
      },
    );
  }

  Widget _buildPendingCard(String docId, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: brandBlue,
              child: Icon(Icons.person_pin, color: Colors.white),
            ),
            title: Text("Patient: ${data['patientName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Relationship: ${data['relationship']}"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('caregiver_requests').doc(docId).delete();
                  },
                  child: const Text("Decline", style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('caregiver_requests')
                        .doc(docId)
                        .update({'status': 'accepted'});

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Accepted ${data['patientName']}'s request!")),
                      );
                    }
                  },
                  child: const Text("Accept Request", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAcceptedCard(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDashboard(patientId: data['patientId']),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Linked to Patient:",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      data['patientName'] ?? 'Unknown',
                      style: const TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Click to view Dashboard",
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
