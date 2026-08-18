import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PharmacyDeliveryScreen extends StatefulWidget {
  const PharmacyDeliveryScreen({super.key});

  @override
  State<PharmacyDeliveryScreen> createState() => _PharmacyDeliveryScreenState();
}

class _PharmacyDeliveryScreenState extends State<PharmacyDeliveryScreen> {
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isChecking = false;
  String _availabilityStatus = '';
  bool _canPlaceOrder = false;
  double _medicinePrice = 0.0;
  final double _deliveryFee = 100.0; // Standard Flat Delivery Charge

  // Check Availability with Delivery Verification
  Future<void> _checkMedicineAndDelivery() async {
    final name = _medicineController.text.trim().toLowerCase();
    if (name.isEmpty) return;

    setState(() {
      _isChecking = true;
      _availabilityStatus = '';
      _canPlaceOrder = false;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('medicines')
          .where('name', isEqualTo: name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final bool isAvailable = data['isAvailable'] ?? false;
        final bool isDeliveryAvailable = data['deliveryAvailable'] ?? true;

        if (isAvailable && isDeliveryAvailable) {
          setState(() {
            _medicinePrice = (data['price'] ?? 0).toDouble();
            _availabilityStatus = "In Stock & Available for Home Delivery!";
            _canPlaceOrder = true;
          });
        } else if (isAvailable && !isDeliveryAvailable) {
          setState(() {
            _availabilityStatus = "Medicine available in-store, but delivery service is disabled for this item.";
          });
        } else {
          setState(() {
            _availabilityStatus = "Medicine is currently out of stock.";
          });
        }
      } else {
        setState(() {
          _availabilityStatus = "Medicine not found in pharmacy inventory.";
        });
      }
    } catch (e) {
      setState(() {
        _availabilityStatus = "Error checking inventory: $e";
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  // Confirm Delivery Order
  Future<void> _submitDeliveryOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete delivery address")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final double totalBill = _medicinePrice + _deliveryFee;

    try {
      await FirebaseFirestore.instance.collection('medicine_orders').add({
        'userId': user.uid,
        'userEmail': user.email,
        'medicineName': _medicineController.text.trim(),
        'deliveryAddress': _addressController.text.trim(),
        'medicinePrice': _medicinePrice,
        'deliveryFee': _deliveryFee,
        'totalAmount': totalBill,
        'paymentMethod': 'Cash on Delivery',
        'deliveryStatus': 'Order Placed (Processing)',
        'estimatedTime': '30 - 45 Minutes',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delivery Order Placed Successfully! Pay cash on delivery.")),
      );

      _medicineController.clear();
      _addressController.clear();
      setState(() {
        _availabilityStatus = '';
        _canPlaceOrder = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to schedule delivery: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Delivery Service"),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _medicineController,
              decoration: const InputDecoration(
                labelText: "Search Medicine for Delivery",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
              onPressed: _isChecking ? null : _checkMedicineAndDelivery,
              child: _isChecking
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Check Delivery Availability", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 15),
            if (_availabilityStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _canPlaceOrder ? Colors.green[50] : Colors.red[50],
                  border: Border.all(color: _canPlaceOrder ? Colors.green : Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _availabilityStatus,
                  style: TextStyle(
                    color: _canPlaceOrder ? Colors.green[900] : Colors.red[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_canPlaceOrder) ...[
              const SizedBox(height: 20),
              const Text("Delivery Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Full Home / Hospital Address",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Payment Breakdown Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Medicine Cost:"),
                          Text("Rs. ${_medicinePrice.toStringAsFixed(0)}"),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Home Delivery Fee:"),
                          Text("Rs. ${_deliveryFee.toStringAsFixed(0)}"),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Payable (COD):", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "Rs. ${(_medicinePrice + _deliveryFee).toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                          SizedBox(width: 5),
                          Text("Est. Delivery Time: 30-45 Mins", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _submitDeliveryOrder,
                icon: const Icon(Icons.pedal_bike, color: Colors.white),
                label: const Text("Confirm & Request Delivery", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}