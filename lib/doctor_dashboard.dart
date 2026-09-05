import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_review_screen.dart';
import 'signup_screen.dart';
import 'patient_dashboard.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  Future<void> _deleteRequest(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('doctor_requests').doc(requestId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request deleted successfully")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting request: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
        ),
        title: const Text("Doctor Portal"),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Pending Requests",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildRequestsList(context, 'Pending', brandBlue),
            
            const Divider(height: 40),
            
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Accepted Requests",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildRequestsList(context, 'Approved', brandBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, String status, Color brandBlue) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_requests')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(status == 'Pending' ? "No pending requests." : "No accepted requests yet.", 
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final data = req.data() as Map<String, dynamic>;
            final patientId = data['patientId'];
            final currentStatus = data['status'] ?? 'Pending';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: currentStatus == 'Approved' ? Colors.green : brandBlue,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(data['patientName'] ?? 'Unknown Patient', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Symptoms: ${data['symptoms'] ?? 'N/A'}"),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          if (patientId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientDashboard(patientId: patientId, isReadOnly: true),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Patient ID not found.")),
                            );
                          }
                        },
                        child: Text(
                          "View Patient Dashboard",
                          style: TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentStatus == 'Approved' ? Colors.blue : Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorReviewScreen(
                                appointmentId: req.id,
                                patientName: data['patientName'] ?? 'Patient',
                                patientCondition: data['symptoms'] ?? 'N/A',
                                collectionName: 'doctor_requests',
                              ),
                            ),
                          );
                        },
                        child: Text(currentStatus == 'Approved' ? "Edit" : "Accept", 
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, req.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Request"),
          content: const Text("Are you sure you want to delete this request?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteRequest(context, requestId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
