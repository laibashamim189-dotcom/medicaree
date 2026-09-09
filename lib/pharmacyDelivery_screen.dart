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
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pharmacyNameController = TextEditingController();
  final TextEditingController _pharmacyAddressController = TextEditingController();
  final TextEditingController _pharmacyEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isSendingRequest = false;
  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _quantityController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyAddressController.dispose();
    _pharmacyEmailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendAvailabilityRequest() async {
    if (widget.isReadOnly) return;
    
    final name = _medicineController.text.trim();
    final quantityStr = _quantityController.text.trim();
    final pName = _pharmacyNameController.text.trim();
    final pAddress = _pharmacyAddressController.text.trim();
    final pEmail = _pharmacyEmailController.text.trim();
    final pPhone = _phoneController.text.trim();

    if (name.isEmpty || quantityStr.isEmpty || pName.isEmpty || pAddress.isEmpty || pEmail.isEmpty || pPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all details")),
      );
      return;
    }

    // Validation Checks
    if (RegExp(r'^[0-9]+$').hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicine name cannot be numeric alone")),
      );
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(quantityStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantity must be numeric")),
      );
      return;
    }

    if (RegExp(r'^[0-9]+$').hasMatch(pName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pharmacy name cannot be numeric alone")),
      );
      return;
    }

    if (!pEmail.contains('@') || !pEmail.contains('.') || !pEmail.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email: must be in name@gmail.com format")),
      );
      return;
    }
    
    final emailNamePart = pEmail.split('@')[0];
    if (RegExp(r'^[0-9]+$').hasMatch(emailNamePart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email prefix cannot be numeric alone")),
      );
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be numeric")),
      );
      return;
    }

    final int quantity = int.tryParse(quantityStr) ?? 1;

    setState(() => _isSendingRequest = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('medicine_orders').add({
        'userId': _effectivePatientId,
        'userEmail': user.email,
        'patientPhone': pPhone,
        'medicineName': name,
        'quantity': quantity,
        'pharmacyName': pName,
        'pharmacyAddress': pAddress,
        'pharmacyManagerEmail': pEmail.toLowerCase().trim(),
        'deliveryStatus': 'Pending (Awaiting Confirmation)',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent to Pharmacy Manager!")),
      );

      _medicineController.clear();
      _quantityController.clear();
      _pharmacyNameController.clear();
      _pharmacyAddressController.clear();
      _pharmacyEmailController.clear();
      _phoneController.clear();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request: $e")),
      );
    } finally {
      setState(() => _isSendingRequest = false);
    }
  }

  Future<void> _showAddressDialog(String orderId) async {
    final TextEditingController addressController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Delivery Address"),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: "Full Home / Hospital Address",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (addressController.text.trim().isEmpty) return;
              
              await FirebaseFirestore.instance.collection('medicine_orders').doc(orderId).update({
                'deliveryAddress': addressController.text.trim(),
                'deliveryStatus': 'Delivery Requested',
              });
              
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Confirm Delivery"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Delivery Service", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Remove back icon
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isReadOnly) ...[
              const Text("Request Medicine Availability", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _medicineController,
                decoration: const InputDecoration(
                  labelText: "Medicine Name",
                  prefixIcon: Icon(Icons.medical_services),
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
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pharmacyNameController,
                decoration: const InputDecoration(
                  labelText: "Pharmacy Name",
                  prefixIcon: Icon(Icons.local_pharmacy),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pharmacyAddressController,
                decoration: const InputDecoration(
                  labelText: "Pharmacy Address",
                  prefixIcon: Icon(Icons.map),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pharmacyEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Pharmacy Manager Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Your Phone Number",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isSendingRequest ? null : _sendAvailabilityRequest,
                child: _isSendingRequest
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Send Request to Pharmacy", style: TextStyle(color: Colors.white)),
              ),
            ],
            const SizedBox(height: 30),
            const Text("Request History & Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicine_orders')
                  .where('userId', isEqualTo: _effectivePatientId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No requests found."));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var order = snapshot.data!.docs[index];
                    var data = order.data() as Map<String, dynamic>;
                    String status = data['deliveryStatus'] ?? 'Pending';
                    int quantity = data['quantity'] ?? 1;
                    
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
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${data['medicineName']} (x$quantity)", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Icon(Icons.info_outline, color: _getStatusColor(status)),
                                ],
                              ),
                              const Divider(),
                              Text("Pharmacy: ${data['pharmacyName']}"),
                              Text("Status: $status", style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                              
                              if (data['medicinePrice'] != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Medicine Cost (x$quantity):"),
                                          Text("Rs. ${(data['medicinePrice'] * quantity).toStringAsFixed(0)}"),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Home Delivery Fee:"),
                                          Text("Rs. ${data['deliveryFee']?.toStringAsFixed(0) ?? '0'}"),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Total Payable (COD):", style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text(
                                            "Rs. ${data['totalAmount']?.toStringAsFixed(0) ?? '0'}",
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
                              ],

                              if (data['deliveryAddress'] != null) ...[
                                const SizedBox(height: 5),
                                Text("Delivery to: ${data['deliveryAddress']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                              
                              const SizedBox(height: 10),
                              if (status == 'In Stock (Provide Address)' && !widget.isReadOnly)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    minimumSize: const Size(double.infinity, 45),
                                  ),
                                  onPressed: () => _showAddressDialog(order.id),
                                  icon: const Icon(Icons.location_on, color: Colors.white),
                                  label: const Text("Enter Delivery Address", style: TextStyle(color: Colors.white)),
                                ),
                              if (status == 'Delivery Requested')
                                const Text("✓ Delivery is being arranged", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
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

  Color _getStatusColor(String status) {
    if (status.contains('In Stock')) return Colors.blue;
    if (status.contains('Requested')) return Colors.green;
    if (status.contains('Rejected') || status.contains('Out of Stock')) return Colors.red;
    return Colors.orange;
  }
}
