import 'package:flutter/material.dart';
import '../models/pharmacy_delivery_model.dart';
import '../view_models/pharmacy_delivery_view_model.dart';

class PharmacyDeliveryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isReadOnly;
  final String? patientId;

  const PharmacyDeliveryScreen({
    super.key,
    this.onBack,
    this.isReadOnly = false,
    this.patientId,
  });

  @override
  State<PharmacyDeliveryScreen> createState() => _PharmacyDeliveryScreenState();
}

class _PharmacyDeliveryScreenState extends State<PharmacyDeliveryScreen> {
  late final PharmacyDeliveryViewModel _viewModel;

  // Controllers
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pharmacyNameController = TextEditingController();
  final TextEditingController _pharmacyAddressController = TextEditingController();
  final TextEditingController _pharmacyEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = PharmacyDeliveryViewModel();
    _viewModel.init(widget.patientId);
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _quantityController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyAddressController.dispose();
    _pharmacyEmailController.dispose();
    _phoneController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleSendRequest() async {
    if (widget.isReadOnly) return;

    final success = await _viewModel.sendAvailabilityRequest(
      name: _medicineController.text.trim(),
      quantityStr: _quantityController.text.trim(),
      pName: _pharmacyNameController.text.trim(),
      pAddress: _pharmacyAddressController.text.trim(),
      pEmail: _pharmacyEmailController.text.trim(),
      pPhone: _phoneController.text.trim(),
      onError: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent to Pharmacy Manager!")),
      );
      _clearFormFields();
    }
  }

  void _clearFormFields() {
    _medicineController.clear();
    _quantityController.clear();
    _pharmacyNameController.clear();
    _pharmacyAddressController.clear();
    _pharmacyEmailController.clear();
    _phoneController.clear();
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandBlue),
            onPressed: () async {
              if (addressController.text.trim().isNotEmpty) {
                await _viewModel.confirmDeliveryAddress(orderId, addressController.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Confirm Delivery", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: brandBlue),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Delivery Service", style: TextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form Section
            if (!widget.isReadOnly) ...[
              const Text(
                "Request Medicine Availability",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _medicineController,
                decoration: _inputDecoration("Medicine Name", Icons.medical_services),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Quantity", Icons.shopping_basket),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pharmacyNameController,
                decoration: _inputDecoration("Pharmacy Name", Icons.local_pharmacy),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pharmacyAddressController,
                decoration: _inputDecoration("Pharmacy Address", Icons.map),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pharmacyEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Pharmacy Manager Email", Icons.email),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Your Phone Number", Icons.phone),
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _viewModel.isSendingRequest ? null : _handleSendRequest,
                    child: _viewModel.isSendingRequest
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text("Send Request to Pharmacy", style: TextStyle(color: Colors.white)),
                  );
                },
              ),
            ],

            const SizedBox(height: 30),
            const Text(
              "Request History & Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Order Stream History
            StreamBuilder<List<MedicineOrderModel>>(
              stream: _viewModel.getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No requests found."));
                }

                final orders = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final Color statusColor = _viewModel.getStatusColor(order.deliveryStatus);

                    return Dismissible(
                      key: Key(order.id),
                      direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.transparent,
                        child: const Icon(Icons.delete, color: Colors.grey),
                      ),
                      onDismissed: (_) => _viewModel.deleteOrder(order.id),
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
                                  Text(
                                    "${order.medicineName} (x${order.quantity})",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Icon(Icons.info_outline, color: statusColor),
                                ],
                              ),
                              const Divider(),
                              Text("Pharmacy: ${order.pharmacyName}"),
                              Text(
                                "Status: ${order.deliveryStatus}",
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                              ),

                              // Pricing Card
                              if (order.medicinePrice != null) ...[
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
                                          Text("Medicine Cost (x${order.quantity}):"),
                                          Text("Rs. ${(order.medicinePrice! * order.quantity).toStringAsFixed(0)}"),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Home Delivery Fee:"),
                                          Text("Rs. ${order.deliveryFee?.toStringAsFixed(0) ?? '0'}"),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Total Payable (COD):", style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text(
                                            "Rs. ${order.totalAmount?.toStringAsFixed(0) ?? '0'}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        children: [
                                          Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                                          SizedBox(width: 5),
                                          Text(
                                            "Est. Delivery Time: 30-45 Mins",
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (order.deliveryAddress != null) ...[
                                const SizedBox(height: 5),
                                Text(
                                  "Delivery to: ${order.deliveryAddress}",
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],

                              const SizedBox(height: 10),
                              if (order.deliveryStatus == 'In Stock (Provide Address)' && !widget.isReadOnly)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    minimumSize: const Size(double.infinity, 45),
                                  ),
                                  onPressed: () => _showAddressDialog(order.id),
                                  icon: const Icon(Icons.location_on, color: Colors.white),
                                  label: const Text("Enter Delivery Address", style: TextStyle(color: Colors.white)),
                                ),
                              if (order.deliveryStatus == 'Delivery Requested')
                                const Text(
                                  "✓ Delivery is being arranged",
                                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
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
}