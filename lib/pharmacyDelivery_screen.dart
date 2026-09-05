import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PharmacyDeliveryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isReadOnly;
  final String? patientId;
  const PharmacyDeliveryScreen({super.key, this.onBack, this.isReadOnly = false, this.patientId});

  @override
  State<PharmacyDeliveryScreen> createState() => _PharmacyDeliveryScreenState();
}

class _PharmacyDeliveryScreenState extends State<PharmacyDeliveryScreen> {
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _isChecking = false;
  String _availabilityStatus = '';
  bool _canPlaceOrder = false;
  double _medicinePrice = 0.0;
  final double _deliveryFee = 100.0;

  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  final Map<String, double> _localInventory = {
    'panadol': 50.0,
    'paracetamol': 40.0,
    'advil': 120.0,
    'ibuprofen': 80.0,
    'aspirin': 30.0,
    'tylenol': 150.0,
    'amoxicillin': 250.0,
    'azithromycin': 450.0,
    'cetirizine': 100.0,
    'loratadine': 110.0,
    'metformin': 200.0,
    'atorvastatin': 600.0,
    'amlodipine': 300.0,
    'lisinopril': 350.0,
    'omeprazole': 180.0,
    'esomeprazole': 220.0,
    'pantoprazole': 190.0,
    'metoprolol': 280.0,
    'simvastatin': 240.0,
    'losartan': 320.0,
    'albuterol': 800.0,
    'fluticasone': 1200.0,
    'montlukast': 550.0,
    'gabapentin': 700.0,
    'sertraline': 900.0,
    'escitalopram': 850.0,
    'fluoxetine': 750.0,
    'alprazolam': 500.0,
    'diazepam': 400.0,
    'lorazepam': 450.0,
    'tramadol': 350.0,
    'hydrocodone': 1500.0,
    'oxycodone': 1800.0,
    'prednisone': 200.0,
    'dexamethasone': 250.0,
    'furosemide': 150.0,
    'spironolactone': 400.0,
    'warfarin': 600.0,
    'clopidogrel': 700.0,
    'levothyroxine': 300.0,
    'insulin': 2500.0,
    'rosuvastatin': 650.0,
    'duloxetine': 950.0,
    'venlafaxine': 880.0,
    'bupropion': 920.0,
    'ciprofloxacin': 400.0,
    'doxycycline': 350.0,
    'meloxicam': 280.0,
    'celecoxib': 550.0,
    'augmentin': 1200.0,
  };

  Future<void> _checkMedicineAndDelivery() async {
    if (widget.isReadOnly) return;
    final name = _medicineController.text.trim().toLowerCase();
    if (name.isEmpty) return;

    setState(() {
      _isChecking = true;
      _availabilityStatus = '';
      _canPlaceOrder = false;
    });

    try {
      if (_localInventory.containsKey(name)) {
        setState(() {
          _medicinePrice = _localInventory[name]!;
          _availabilityStatus = "In Stock & Available for Home Delivery!";
          _canPlaceOrder = true;
        });
        return;
      }

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

  Future<void> _submitDeliveryOrder() async {
    if (widget.isReadOnly) return;
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete delivery address")),
      );
      return;
    }

    final int quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid quantity")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final double totalBill = (_medicinePrice * quantity) + _deliveryFee;

    try {
      await FirebaseFirestore.instance.collection('medicine_orders').add({
        'userId': _effectivePatientId,
        'userEmail': user.email,
        'medicineName': _medicineController.text.trim(),
        'quantity': quantity,
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
      _quantityController.clear();
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
    int currentQuantity = int.tryParse(_quantityController.text) ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Delivery Service", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isReadOnly) ...[
              TextField(
                controller: _medicineController,
                decoration: const InputDecoration(
                  labelText: "Search Medicine for Delivery",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  prefixIcon: Icon(Icons.shopping_basket),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isChecking ? null : _checkMedicineAndDelivery,
                child: _isChecking
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Check Delivery Availability", style: TextStyle(color: Colors.white)),
              ),
            ],
            const SizedBox(height: 15),
            if (_availabilityStatus.isNotEmpty && !widget.isReadOnly)
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
            if (_canPlaceOrder && !widget.isReadOnly) ...[
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
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Medicine Cost (x$currentQuantity):"),
                          Text("Rs. ${(_medicinePrice * currentQuantity).toStringAsFixed(0)}"),
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
                            "Rs. ${(_medicinePrice * currentQuantity + _deliveryFee).toStringAsFixed(0)}",
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
            ],
            const SizedBox(height: 20),
            const Text("Order History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicine_orders')
                  .where('userId', isEqualTo: _effectivePatientId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No orders found."));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var order = snapshot.data!.docs[index];
                    var data = order.data() as Map<String, dynamic>;
                    return Dismissible(
                      key: Key(order.id),
                      direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.transparent,
                        child: const Icon(Icons.delete, color: Colors.grey),
                      ),
                      onDismissed: (direction) {
                        FirebaseFirestore.instance.collection('medicine_orders').doc(order.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Order history deleted")),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text("${data['medicineName']} (x${data['quantity']})"),
                          subtitle: Text("Status: ${data['deliveryStatus']}\nTotal: Rs. ${data['totalAmount']}"),
                          trailing: const Icon(Icons.local_shipping, color: Color(0xFF1565C0)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
