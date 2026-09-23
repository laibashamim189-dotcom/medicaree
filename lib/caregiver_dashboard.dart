import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'patient_dashboard.dart';
import 'login_screen.dart';
import 'DirectChatScreen.dart';
import 'notification_service.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _listenForNotifications();
    NotificationService.updateFCMToken();
  }

  void _listenForNotifications() {
    if (currentUser == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('toId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          NotificationService.showImmediateNotification(
            id: change.doc.id.hashCode,
            title: data['title'] ?? "New Alert",
            body: data['body'] ?? "",
            channelId: data['type'] == 'chat' ? 'chat_messages' : 'medication_urgent_v9',
          );
          change.doc.reference.update({'status': 'delivered'});
        }
      }
    });
  }

  Future<void> _navigateToPatientDashboard(String patientId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: brandBlue)),
    );

    try {
      var docReqSnap = await FirebaseFirestore.instance
          .collection('doctor_requests')
          .where('patientId', isEqualTo: patientId)
          .get();

      bool isReadOnly = true; 
      if (docReqSnap.docs.isNotEmpty) {
        var approvedDocs = docReqSnap.docs.where((doc) => doc['status'] == 'Approved').toList();
        if (approvedDocs.isNotEmpty) {
          approvedDocs.sort((a, b) {
            var t1 = a['timestamp'] as Timestamp?;
            var t2 = b['timestamp'] as Timestamp?;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });

          var latestDoc = approvedDocs.first.data() as Map<String, dynamic>;
          var recs = latestDoc['recommendations'] as Map<String, dynamic>?;
          if (recs != null) {
            String managedBy = (recs['managedBy'] ?? '').toString().toLowerCase();
            if (managedBy == 'both') isReadOnly = false;
          }
        }
      }

      if (mounted) {
        Navigator.pop(context); 
        Navigator.push(context, MaterialPageRoute(builder: (context) => PatientDashboard(patientId: patientId, isReadOnly: isReadOnly)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Please log in")));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          title: const Text("Caregiver Dashboard", style: TextStyle(color: Colors.white)),
          backgroundColor: brandBlue,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            }),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(icon: Icon(Icons.mail_outline), text: "Incoming"), Tab(icon: Icon(Icons.people_outline), text: "Accepted")],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('caregiver_requests')
              .where('caregiverEmail', isEqualTo: currentUser!.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No patient requests found"));

            final allRequests = snapshot.data!.docs.toList();
            allRequests.sort((a, b) {
              var t1 = a['timestamp'] as Timestamp?;
              var t2 = b['timestamp'] as Timestamp?;
              if (t1 == null) return 1;
              if (t2 == null) return -1;
              return t2.compareTo(t1);
            });

            final pendingRequests = allRequests.where((doc) => doc['status'] != 'accepted').toList();
            final acceptedRequests = allRequests.where((doc) => doc['status'] == 'accepted').toList();

            return TabBarView(children: [_buildIncomingList(pendingRequests), _buildAcceptedList(acceptedRequests)]);
          },
        ),
      ),
    );
  }

  Widget _buildIncomingList(List<QueryDocumentSnapshot> requests) {
    if (requests.isEmpty) return const Center(child: Text("No new incoming requests", style: TextStyle(color: Colors.grey)));
    return ListView.builder(padding: const EdgeInsets.all(15), itemCount: requests.length, itemBuilder: (context, index) => _buildPendingCard(requests[index].id, requests[index].data() as Map<String, dynamic>));
  }

  Widget _buildAcceptedList(List<QueryDocumentSnapshot> requests) {
    if (requests.isEmpty) return const Center(child: Text("No accepted patients yet", style: TextStyle(color: Colors.grey)));
    return ListView.builder(padding: const EdgeInsets.all(15), itemCount: requests.length, itemBuilder: (context, index) => _buildAcceptedCard(requests[index].data() as Map<String, dynamic>));
  }

  Widget _buildPendingCard(String docId, Map<String, dynamic> data) {
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        ListTile(leading: const CircleAvatar(backgroundColor: brandBlue, child: Icon(Icons.person_pin, color: Colors.white)), title: Text("Patient: ${data['patientName']}", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Relationship: ${data['relationship']}")),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => FirebaseFirestore.instance.collection('caregiver_requests').doc(docId).delete(), child: const Text("Decline", style: TextStyle(color: Colors.red))),
          const SizedBox(width: 8),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () async {
            await FirebaseFirestore.instance.collection('caregiver_requests').doc(docId).update({'status': 'accepted', 'caregiverId': currentUser!.uid});
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Accepted ${data['patientName']}'s request!")));
          }, child: const Text("Accept Request", style: TextStyle(color: Colors.white))),
        ]))
      ]),
    );
  }

  Widget _buildAcceptedCard(Map<String, dynamic> data) {
    final String patientId = data['patientId'] ?? "";
    final String chatId = DirectChatScreen.getChatId(currentUser!.uid, patientId);
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      InkWell(onTap: () => _navigateToPatientDashboard(patientId), child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Patient:", style: TextStyle(color: Colors.grey[600], fontSize: 12)), Text(data['patientName'] ?? 'Unknown', style: const TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)), const Text("Tap to view Dashboard", style: TextStyle(color: Colors.green, fontSize: 11))])),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ])),
      const Divider(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        StreamBuilder<DocumentSnapshot>(stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(), builder: (context, snapshot) {
          bool hasUnread = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            final chatData = snapshot.data!.data() as Map<String, dynamic>;
            if (chatData['lastSenderId'] == patientId && chatData['isRead'] == false) hasUnread = true;
          }
          return Stack(clipBehavior: Clip.none, children: [
            SizedBox(height: 38, child: ElevatedButton.icon(onPressed: () { FirebaseFirestore.instance.collection('chats').doc(chatId).update({'isRead': true}); Navigator.push(context, MaterialPageRoute(builder: (context) => DirectChatScreen(doctorId: currentUser!.uid, patientId: patientId, receiverName: data['patientName'] ?? "Patient"))); }, icon: const Icon(Icons.chat_bubble_outline, size: 16), label: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: brandBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16)))),
            if (hasUnread) Positioned(right: 4, top: -3, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 12, minHeight: 12))),
          ]);
        }),
      ]),
    ]))));
  }
}
