import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'login_screen.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _updateOrderStatus(String orderId, String newStatus, {Map<String, dynamic>? additionalData}) async {
    try {
      Map<String, dynamic> updateData = {'deliveryStatus': newStatus};
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }
      
      await FirebaseFirestore.instance
          .collection('medicine_orders')
          .doc(orderId)
          .update(updateData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order Updated: $newStatus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update order: $e")),
        );
      }
    }
  }

  // Soft delete logic for pharmacy orders
  Future<void> _performSoftDelete(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medicine_orders')
          .doc(orderId)
          .update({'deletedByPharmacy': true});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order removed from dashboard")),
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

  Future<void> _showConfirmStockDialog(String orderId, int quantity) async {
    final TextEditingController costController = TextEditingController();
    final TextEditingController deliveryFeeController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Stock & Set Pricing"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Medicine Cost (Per Unit)",
                prefixText: "Rs. ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: deliveryFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Home Delivery Fee",
                prefixText: "Rs. ",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final double cost = double.tryParse(costController.text.trim()) ?? 0.0;
              final double deliveryFee = double.tryParse(deliveryFeeController.text.trim()) ?? 0.0;
              final double total = (cost * quantity) + deliveryFee;

              _updateOrderStatus(orderId, 'In Stock (Provide Address)', additionalData: {
                'medicinePrice': cost,
                'deliveryFee': deliveryFee,
                'totalAmount': total,
              });
              Navigator.pop(context);
            },
            child: const Text("Confirm & Send Pricing"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);
    final String managerEmail = user?.email?.toLowerCase().trim() ?? "";

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Pharmacy Dashboard"),
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(icon: Icon(Icons.email), text: "Incoming"),
              Tab(icon: Icon(Icons.people), text: "Accepted"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: managerEmail.isEmpty 
        ? const Center(child: Text("User email not found. Please login again."))
        : TabBarView(
            children: [
              _buildOrderList(managerEmail, isIncoming: true),
              _buildOrderList(managerEmail, isIncoming: false),
            ],
          ),
      ),
    );
  }

  Widget _buildOrderList(String managerEmail, {required bool isIncoming}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medicine_orders')
          .where('pharmacyManagerEmail', isEqualTo: managerEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(isIncoming ? "No new incoming requests" : "No accepted requests"));
        }

        // Local filtering by status and delete flag
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['deletedByPharmacy'] == true) return false;
          
          final status = data['deliveryStatus'] ?? '';
          if (isIncoming) {
            return status == 'Pending (Awaiting Confirmation)';
          } else {
            return [
              'In Stock (Provide Address)',
              'Delivery Requested',
              'Confirmed (Out for Delivery)',
              'Rejected (Out of Stock)'
            ].contains(status);
          }
        }).toList();

        // Sorting by timestamp descending
        filteredDocs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timestampA = dataA['timestamp'] as Timestamp?;
          final timestampB = dataB['timestamp'] as Timestamp?;
          
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          return timestampB.compareTo(timestampA);
        });

        if (filteredDocs.isEmpty) {
          return Center(child: Text(isIncoming ? "No new incoming requests" : "No accepted requests"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var order = filteredDocs[index];
            var data = order.data() as Map<String, dynamic>;
            String status = data['deliveryStatus'] ?? 'Pending';

            Widget cardContent = Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['medicineName'] ?? "Unknown Medicine",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Patient: ${data['userEmail'] ?? 'N/A'}"),
                    Text("Phone: ${data['patientPhone'] ?? 'N/A'}"), // Added Patient Phone Number
                    Text("Quantity: ${data['quantity']}"),
                    if (data['medicinePrice'] != null)
                       Text("Medicine Cost: Rs. ${data['medicinePrice']}"),
                    if (data['deliveryFee'] != null)
                       Text("Delivery Fee: Rs. ${data['deliveryFee']}"),
                    if (data['totalAmount'] != null)
                       Text("Total Amount: Rs. ${data['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    if (data['deliveryAddress'] != null)
                      Text("Address: ${data['deliveryAddress']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const Divider(height: 25),
                    
                    if (status == 'Pending (Awaiting Confirmation)') 
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _showConfirmStockDialog(order.id, data['quantity'] ?? 1),
                              child: const Text("Confirm Stock", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => _updateOrderStatus(order.id, 'Rejected (Out of Stock)'),
                              child: const Text("Reject Request", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      
                    if (status == 'Delivery Requested')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        onPressed: () => _updateOrderStatus(order.id, 'Confirmed (Out for Delivery)'),
                        icon: const Icon(Icons.local_shipping, color: Colors.white),
                        label: const Text("Mark as Out for Delivery", style: TextStyle(color: Colors.white)),
                      ),
                    
                    if (status == 'Confirmed (Out for Delivery)')
                      const Center(
                        child: Text("Order is on the way!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            );

            if (!isIncoming) {
              return Slidable(
                key: Key(order.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.2,
                  dismissible: DismissiblePane(onDismissed: () => _performSoftDelete(order.id)),
                  children: [
                    SlidableAction(
                      onPressed: (context) => _performSoftDelete(order.id),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.grey,
                      icon: Icons.delete,
                    ),
                  ],
                ),
                child: cardContent,
              );
            }

            return cardContent;
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Confirmed') || status.contains('Requested')) return Colors.green;
    if (status.contains('In Stock')) return Colors.blue;
    if (status.contains('Rejected') || status.contains('Out of Stock')) return Colors.red;
    return Colors.orange;
  }
}
