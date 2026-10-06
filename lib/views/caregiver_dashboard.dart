import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/caregiver_request_model.dart';
import '../view_models/caregiver_dashboard_view_model.dart';
import '../view_models/direct_chat_view_model.dart';
import 'patient_dashboard_screen.dart';
import 'login_screen.dart';
import 'direct_chat_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CaregiverDashboardViewModel>(context, listen: false).init();
    });
  }

  Future<void> _navigateToPatientDashboard(CaregiverDashboardViewModel viewModel, String patientId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: brandBlue)),
    );

    try {
      bool isReadOnly = await viewModel.checkPatientReadOnlyAccess(patientId);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDashboard(patientId: patientId, isReadOnly: isReadOnly),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showDeleteConfirmation(CaregiverDashboardViewModel viewModel, CaregiverRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Patient"),
        content: Text("Are you sure you want to remove ${request.patientName} from your list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.declineRequest(request.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Removed ${request.patientName} successfully")),
                );
              }
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CaregiverDashboardViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.currentUser == null) {
          return const Scaffold(body: Center(child: Text("Please log in")));
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text("Caregiver Dashboard", style: TextStyle(color: Colors.white)),
              backgroundColor: brandBlue,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await viewModel.logout();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
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
                ],
              ),
            ),
            body: StreamBuilder<List<CaregiverRequestModel>>(
              stream: viewModel.getCaregiverRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No patient requests found"));
                }

                final pendingRequests = snapshot.data!.where((doc) => doc.status != 'accepted').toList();
                final acceptedRequests = snapshot.data!.where((doc) => doc.status == 'accepted').toList();

                return TabBarView(
                  children: [
                    _buildIncomingList(pendingRequests, viewModel),
                    _buildAcceptedList(acceptedRequests, viewModel),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingList(List<CaregiverRequestModel> requests, CaregiverDashboardViewModel viewModel) {
    if (requests.isEmpty) {
      return const Center(child: Text("No new incoming requests", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildPendingCard(requests[index], viewModel),
    );
  }

  Widget _buildAcceptedList(List<CaregiverRequestModel> requests, CaregiverDashboardViewModel viewModel) {
    if (requests.isEmpty) {
      return const Center(child: Text("No accepted patients yet", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildAcceptedCard(requests[index], viewModel),
    );
  }

  Widget _buildPendingCard(CaregiverRequestModel request, CaregiverDashboardViewModel viewModel) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: brandBlue, child: Icon(Icons.person_pin, color: Colors.white)),
            title: Text("Patient: ${request.patientName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Relationship: ${request.relationship}"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => viewModel.declineRequest(request.id),
                  child: const Text("Decline", style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    viewModel.acceptRequest(request.id, request.patientName, () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Accepted ${request.patientName}'s request!")),
                        );
                      }
                    });
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

  Widget _buildAcceptedCard(CaregiverRequestModel request, CaregiverDashboardViewModel viewModel) {
    final String chatId = DirectChatScreen.getChatId(viewModel.currentUser!.uid, request.patientId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(request.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => _showDeleteConfirmation(viewModel, request),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.grey,
              icon: Icons.delete_outline,
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                InkWell(
                  onTap: () => _navigateToPatientDashboard(viewModel, request.patientId),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Patient:", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text(request.patientName, style: const TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text("Tap to view Dashboard", style: TextStyle(color: Colors.green, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                      builder: (context, snapshot) {
                        bool hasUnread = false;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final chatData = snapshot.data!.data() as Map<String, dynamic>;
                          if (chatData['lastSenderId'] != viewModel.currentUser!.uid && chatData['isRead'] == false) {
                            hasUnread = true;
                          }
                        }
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  viewModel.markChatAsRead(chatId);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChangeNotifierProvider(
                                        create: (_) => DirectChatViewModel(),
                                        child: DirectChatScreen(
                                          doctorId: viewModel.currentUser!.uid,
                                          patientId: request.patientId,
                                          receiverName: request.patientName,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Positioned(
                                right: 4,
                                top: -3,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
