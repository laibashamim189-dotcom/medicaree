import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'doctor_review_screen.dart';
import 'patient_dashboard.dart';
import 'DirectChatScreen.dart';
import 'login_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  static const Color brandBlue = Color(0xFF1565C0);

  // Soft delete logic for doctor requests: updates a flag instead of deleting the document
  Future<void> _performSoftDelete(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctor_requests')
          .doc(requestId)
          .update({'deletedByDoctor': true});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request removed from dashboard")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // Soft delete logic for payments: updates a flag instead of deleting the document
  Future<void> _performPaymentSoftDelete(String paymentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .update({'deletedByDoctor': true});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment record removed")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          title: const Text("Doctor Dashboard"),
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.mail_outline), text: "Incoming"),
              Tab(icon: Icon(Icons.people_outline), text: "Accepted"),
              Tab(icon: Icon(Icons.payments_outlined), text: "Payments"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestsList(context, 'Pending'),
            _buildRequestsList(context, 'Approved'),
            _buildPaymentsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, String status) {
    final String currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final String currentDoctorEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    Query query = FirebaseFirestore.instance.collection('doctor_requests').where('status', isEqualTo: status);
    if (status == 'Pending') {
      query = query.where('doctorEmail', isEqualTo: currentDoctorEmail);
    } else {
      query = query.where('doctorId', isEqualTo: currentDoctorId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data?.docs ?? [];
        final requests = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['deletedByDoctor'] != true;
        }).toList();

        if (requests.isEmpty) {
          return Center(child: Text("No $status requests.", style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final data = req.data() as Map<String, dynamic>;
            final patientId = data['patientId'] ?? "";
            final currentStatus = data['status'] ?? 'Pending';
            final chatId = DirectChatScreen.getChatId(currentDoctorId, patientId);

            return Slidable(
              key: Key(req.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                dismissible: DismissiblePane(onDismissed: () => _performSoftDelete(req.id)),
                children: [
                  SlidableAction(
                    onPressed: (context) => _performSoftDelete(req.id),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.grey,
                    icon: Icons.delete,
                  ),
                ],
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['patientName'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          _buildStatusChip(currentStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSymptomsInfo(context, data, patientId),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (currentStatus == 'Approved') ...[
                            _buildChatWithBadge(context, chatId, currentDoctorId, patientId, data['patientName'] ?? "Patient"),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: currentStatus == 'Approved' ? Colors.blue : Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorReviewScreen(
                                appointmentId: req.id,
                                patientId: patientId,
                                patientName: data['patientName'] ?? 'Patient',
                                patientCondition: data['symptoms'] ?? 'N/A',
                                collectionName: 'doctor_requests',
                              )));
                            },
                            child: Text(currentStatus == 'Approved' ? "Edit Recommendations" : "Accept & Review", style: const TextStyle(color: Colors.white)),
                          ),
                        ],
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

  Widget _buildChatWithBadge(BuildContext context, String chatId, String doctorId, String patientId, String patientName) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final chatData = snapshot.data!.data() as Map<String, dynamic>;
          if (chatData['lastSenderId'] != doctorId && chatData['isRead'] == false) {
            hasUnread = true;
          }
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 28),
              onPressed: () {
                FirebaseFirestore.instance.collection('chats').doc(chatId).update({'isRead': true});
                Navigator.push(context, MaterialPageRoute(builder: (context) => DirectChatScreen(
                  doctorId: doctorId,
                  patientId: patientId,
                  receiverName: patientName,
                )));
              },
            ),
            if (hasUnread)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'Approved') color = Colors.green;
    if (status == 'Rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildSymptomsInfo(BuildContext context, Map<String, dynamic> data, String? patientId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1EBF7))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Symptoms Reported", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(data['symptoms'] ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Divider(color: Color(0xFFBBDEFB)),
          InkWell(
            onTap: () { if (patientId != null) Navigator.push(context, MaterialPageRoute(builder: (context) => PatientDashboard(patientId: patientId, isReadOnly: true))); },
            child: const Row(children: [Icon(Icons.dashboard_outlined, size: 20, color: brandBlue), SizedBox(width: 8), Text("View Patient Dashboard", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 13)), Spacer(), Icon(Icons.arrow_forward_ios, size: 12, color: brandBlue)]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(BuildContext context) {
    final String currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('doctorId', isEqualTo: currentDoctorId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data?.docs ?? [];
        final payments = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['deletedByDoctor'] != true;
        }).toList();

        if (payments.isEmpty) {
          return const Center(child: Text("No payments found.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final doc = payments[index];
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? 'Pending';
            final String imageUrl = data['screenshotUrl'] ?? "";

            return Slidable(
              key: Key(doc.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                dismissible: DismissiblePane(onDismissed: () => _performPaymentSoftDelete(doc.id)),
                children: [
                  SlidableAction(
                    onPressed: (context) => _performPaymentSoftDelete(doc.id),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.grey,
                    icon: Icons.delete,
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (imageUrl.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: InteractiveViewer(child: Image.network(imageUrl)),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(imageUrl, fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['patientName'] ?? 'Patient',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "ID: ${data['transactionId'] ?? 'N/A'}",
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Status: $status",
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (status != 'Pending') _buildStatusChip(status),
                        ],
                      ),
                      if (status == 'Pending') ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _updatePaymentStatus(context, doc.id, 'Rejected'),
                                child: const Text("Reject"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _updatePaymentStatus(context, doc.id, 'Approved'),
                                child: const Text("Approve"),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Color _getStatusColor(String status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Rejected') return Colors.red;
    return Colors.orange;
  }

  Future<void> _updatePaymentStatus(BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(docId).update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment $newStatus")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
