import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'login_screen.dart';
import '../models/pharmacy_order_model.dart';
import '../view_models/pharmacy_dashboard_view_model.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  late final PharmacyDashboardViewModel _viewModel;
  final Color brandBlue = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = PharmacyDashboardViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleOrderStatusUpdate(String orderId, String newStatus, {Map<String, dynamic>? additionalData}) async {
    final error = await _viewModel.updateOrderStatus(orderId, newStatus, additionalData: additionalData);
    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order Updated: $newStatus")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update order: $error")));
    }
  }

  Future<void> _handleSoftDelete(String orderId) async {
    final error = await _viewModel.performSoftDelete(orderId);
    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order removed from dashboard")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
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
            onPressed: () async {
              Navigator.pop(context);
              final error = await _viewModel.confirmStockAndPricing(
                orderId: orderId,
                quantity: quantity,
                costText: costController.text,
                deliveryFeeText: deliveryFeeController.text,
              );
              if (mounted) {
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Updated: In Stock")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $error")));
                }
              }
            },
            child: const Text("Confirm & Send Pricing"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.currentUser == null) return const LoginScreen();

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
                await _viewModel.signOut();
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
        body: _viewModel.managerEmail.isEmpty
            ? const Center(child: Text("User email not found. Please login again."))
            : TabBarView(
          children: [
            _buildOrderList(isIncoming: true),
            _buildOrderList(isIncoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList({required bool isIncoming}) {
    return StreamBuilder<List<PharmacyOrderModel>>(
      stream: _viewModel.getOrdersStream(isIncoming: isIncoming),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(isIncoming ? "No new incoming requests" : "No accepted requests"));
        }

        final orders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final String status = order.deliveryStatus;

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
                            order.medicineName ?? "Unknown Medicine",
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
                    Text("Patient: ${order.userEmail ?? 'N/A'}"),
                    Text("Phone: ${order.patientPhone ?? 'N/A'}"),
                    Text("Quantity: ${order.quantity}"),
                    if (order.medicinePrice != null) Text("Medicine Cost: Rs. ${order.medicinePrice}"),
                    if (order.deliveryFee != null) Text("Delivery Fee: Rs. ${order.deliveryFee}"),
                    if (order.totalAmount != null)
                      Text("Total Amount: Rs. ${order.totalAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    if (order.deliveryAddress != null)
                      Text("Address: ${order.deliveryAddress}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const Divider(height: 25),
                    if (status == 'Pending (Awaiting Confirmation)')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _showConfirmStockDialog(order.id, order.quantity),
                              child: const Text("Confirm Stock", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => _handleOrderStatusUpdate(order.id, 'Rejected (Out of Stock)'),
                              child: const Text("Reject Request", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    if (status == 'Delivery Requested')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 45)),
                        onPressed: () => _handleOrderStatusUpdate(order.id, 'Confirmed (Out for Delivery)'),
                        icon: const Icon(Icons.local_shipping, color: Colors.white),
                        label: const Text("Mark as Out for Delivery", style: TextStyle(color: Colors.white)),
                      ),
                    if (status == 'Confirmed (Out for Delivery)')
                      const Center(child: Text("Order is on the way!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
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
                  dismissible: DismissiblePane(onDismissed: () => _handleSoftDelete(order.id)),
                  children: [
                    SlidableAction(
                      onPressed: (context) => _handleSoftDelete(order.id),
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
