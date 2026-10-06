import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../view_models/payment_view_model.dart';

class PaymentScreen extends StatefulWidget {
  final String? initialDoctorId;
  const PaymentScreen({super.key, this.initialDoctorId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PaymentViewModel _viewModel;

  final Color brandBlue = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentViewModel();
    _viewModel.initialize(widget.initialDoctorId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final errorMessage = await _viewModel.submitPayment();

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment submitted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Pay Doctor", style: TextStyle(color: Colors.white)),
            backgroundColor: brandBlue,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Make a Payment",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Enter payment details shared in chat.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 25),

                  const Text("Doctor Name", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _viewModel.doctorNameController,
                    readOnly: _viewModel.selectedDoctorId != null,
                    decoration: InputDecoration(
                      hintText: "Enter Doctor Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF1565C0)),
                      filled: _viewModel.selectedDoctorId != null,
                      fillColor: _viewModel.selectedDoctorId != null ? Colors.grey[100] : Colors.transparent,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? "Enter doctor name" : null,
                  ),

                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: brandBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: brandBlue.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Payment Information",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),

                        const Text("Select Method", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _methodCard("EasyPaisa", Colors.green, _viewModel.selectedMethod == 'EasyPaisa'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _methodCard("JazzCash", Colors.orange, _viewModel.selectedMethod == 'JazzCash'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _viewModel.paymentNumberController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Doctor's Payment Number",
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.phone_android,
                              size: 20,
                              color: _viewModel.selectedMethod == 'EasyPaisa' ? Colors.green : Colors.orange,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) => value == null || value.isEmpty ? "Enter number" : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text("Transaction Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _viewModel.transactionIdController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Transaction ID",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.tag, size: 20),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Enter ID" : null,
                  ),
                  const SizedBox(height: 20),
                  const Text("Payment Screenshot", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _viewModel.pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      child: _viewModel.screenshotFile == null
                          ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          Text("Upload Screenshot", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_viewModel.screenshotFile!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _viewModel.isSubmitting ? null : _handlePaymentSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _viewModel.isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SUBMIT PAYMENT",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _viewModel.selectedDoctorId != null
                        ? "Payment History with ${_viewModel.doctorNameController.text}"
                        : "Payment History",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                  ),
                  const SizedBox(height: 15),
                  _buildPaymentHistory(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
    return StreamBuilder<List<PaymentRecord>>(
      stream: _viewModel.getPaymentHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No relevant payment history found.", style: TextStyle(color: Colors.grey)),
          );
        }

        final payments = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final record = payments[index];
            final String status = record.status;

            Color statusColor = Colors.orange;
            if (status == 'Approved') statusColor = Colors.green;
            if (status == 'Rejected') statusColor = Colors.red;

            return Dismissible(
              key: Key(record.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                await _viewModel.deletePaymentRecord(record.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment record deleted")),
                  );
                }
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    record.doctorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ID: ${record.transactionId}"),
                      Text("${record.paymentMethod} - ${record.paymentNumber}"),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _methodCard(String method, Color color, bool isSelected) {
    return InkWell(
      onTap: () => _viewModel.setSelectedMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, color: color, size: 18),
            const SizedBox(width: 8),
            Text(method,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black54,
                )),
          ],
        ),
      ),
    );
  }
}