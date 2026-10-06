import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/doctor_dashboard_models.dart';
import '../view_models/doctor_dashboard_view_model.dart';
import '../view_models/direct_chat_view_model.dart';
import 'direct_chat_screen.dart';
import 'doctor_review_screen.dart';
import 'login_screen.dart';
import 'patient_dashboard_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorDashboardViewModel>(context, listen: false).initNotificationListener();
    });
  }

  Color _getStatusColor(String status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Rejected') return Colors.red;
    return Colors.orange;
  }

  void _showSnackBar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DoctorDashboardViewModel>(context, listen: false);

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
                await viewModel.signOut();
                if (context.mounted) {
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
    final viewModel = Provider.of<DoctorDashboardViewModel>(context, listen: false);

    return StreamBuilder<List<DoctorRequestModel>>(
      stream: viewModel.getRequestsStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(child: Text("No $status requests.", style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final chatId = DirectChatScreen.getChatId(viewModel.currentDoctorId, req.patientId);

            return Slidable(
              key: Key(req.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                dismissible: DismissiblePane(onDismissed: () async {
                  try {
                    await viewModel.performSoftDelete(req.id);
                    _showSnackBar("Request removed from dashboard");
                  } catch (e) {
                    _showSnackBar("Error: $e");
                  }
                }),
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      try {
                        await viewModel.performSoftDelete(req.id);
                        _showSnackBar("Request removed from dashboard");
                      } catch (e) {
                        _showSnackBar("Error: $e");
                      }
                    },
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
                          Text(req.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          _buildStatusChip(req.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSymptomsInfo(context, req.symptoms, req.patientId),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (req.status == 'Approved') ...[
                            _buildChatWithBadge(context, chatId, viewModel.currentDoctorId, req.patientId, req.patientName),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: req.status == 'Approved' ? Colors.blue : Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DoctorReviewScreen(
                                    appointmentId: req.id,
                                    patientId: req.patientId,
                                    patientName: req.patientName,
                                    patientCondition: req.symptoms,
                                    collectionName: 'doctor_requests',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              req.status == 'Approved' ? "Edit Recommendations" : "Accept & Review",
                              style: const TextStyle(color: Colors.white),
                            ),
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
    final viewModel = Provider.of<DoctorDashboardViewModel>(context, listen: false);

    return StreamBuilder<bool>(
      stream: viewModel.getUnreadChatStream(chatId),
      builder: (context, snapshot) {
        bool hasUnread = snapshot.data ?? false;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 28),
              onPressed: () {
                viewModel.markChatAsRead(chatId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => DirectChatViewModel(),
                      child: DirectChatScreen(
                        doctorId: doctorId,
                        patientId: patientId,
                        receiverName: patientName,
                      ),
                    ),
                  ),
                );
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
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildSymptomsInfo(BuildContext context, String symptoms, String patientId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1EBF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Symptoms Reported", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(symptoms, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Divider(color: Color(0xFFBBDEFB)),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDashboard(patientId: patientId, isReadOnly: true),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.dashboard_outlined, size: 20, color: brandBlue),
                SizedBox(width: 8),
                Text("View Patient Dashboard", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                Spacer(),
                Icon(Icons.arrow_forward_ios, size: 12, color: brandBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(BuildContext context) {
    final viewModel = Provider.of<DoctorDashboardViewModel>(context, listen: false);

    return StreamBuilder<List<PaymentModel>>(
      stream: viewModel.getPaymentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return const Center(child: Text("No payments found.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];

            return Slidable(
              key: Key(payment.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                dismissible: DismissiblePane(onDismissed: () async {
                  try {
                    await viewModel.performPaymentSoftDelete(payment.id);
                    _showSnackBar("Payment record removed");
                  } catch (e) {
                    _showSnackBar("Error: $e");
                  }
                }),
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      try {
                        await viewModel.performPaymentSoftDelete(payment.id);
                        _showSnackBar("Payment record removed");
                      } catch (e) {
                        _showSnackBar("Error: $e");
                      }
                    },
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
                              if (payment.screenshotUrl.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: InteractiveViewer(child: Image.network(payment.screenshotUrl)),
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
                              child: payment.screenshotUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(payment.screenshotUrl, fit: BoxFit.cover),
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
                                  payment.patientName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "ID: ${payment.transactionId}",
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Status: ${payment.status}",
                                  style: TextStyle(
                                    color: _getStatusColor(payment.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (payment.status != 'Pending') _buildStatusChip(payment.status),
                        ],
                      ),
                      if (payment.status == 'Pending') ...[
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
                                onPressed: () async {
                                  try {
                                    await viewModel.updatePaymentStatus(payment.id, 'Rejected');
                                    _showSnackBar("Payment Rejected");
                                  } catch (e) {
                                    _showSnackBar("Error: $e");
                                  }
                                },
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
                                onPressed: () async {
                                  try {
                                    await viewModel.updatePaymentStatus(payment.id, 'Approved');
                                    _showSnackBar("Payment Approved");
                                  } catch (e) {
                                    _showSnackBar("Error: $e");
                                  }
                                },
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
}
