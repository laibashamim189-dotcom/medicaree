import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class PaymentScreen extends StatefulWidget {
  final String? initialDoctorId;
  const PaymentScreen({super.key, this.initialDoctorId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  final _paymentNumberController = TextEditingController();
  final _doctorNameController = TextEditingController();
  
  String? selectedDoctorId;
  String selectedMethod = 'EasyPaisa'; 
  
  File? _screenshotFile;
  bool _isSubmitting = false;

  final Color brandBlue = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    if (widget.initialDoctorId != null) {
      selectedDoctorId = widget.initialDoctorId;
      _loadDoctorName(widget.initialDoctorId!);
    }
  }

  Future<void> _loadDoctorName(String docId) async {
    try {
      var docSnap = await FirebaseFirestore.instance.collection('users').doc(docId).get();
      if (docSnap.exists) {
        setState(() {
          _doctorNameController.text = docSnap.data()?['name'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error loading doctor details: $e");
    }
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _paymentNumberController.dispose();
    _doctorNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _screenshotFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPayment() async {
    final String doctorName = _doctorNameController.text.trim();
    if (doctorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter doctor name")));
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    
    if (_screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload payment screenshot")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = await CloudinaryService.uploadImage(_screenshotFile!);
      
      if (imageUrl == null) {
         throw Exception("Upload failed");
      }

      final user = FirebaseAuth.instance.currentUser;
      final patientDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final patientName = patientDoc.exists ? (patientDoc.data()?['name'] ?? "Patient") : "Patient";

      await FirebaseFirestore.instance.collection('payments').add({
        'patientId': user?.uid,
        'patientName': patientName,
        'doctorId': selectedDoctorId, 
        'doctorName': doctorName,
        'transactionId': _transactionIdController.text.trim(),
        'paymentNumber': _paymentNumberController.text.trim(),
        'paymentMethod': selectedMethod,
        'screenshotUrl': imageUrl,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment submitted successfully!")),
        );
        _transactionIdController.clear();
        _paymentNumberController.clear();
        setState(() {
          _screenshotFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                controller: _doctorNameController,
                readOnly: selectedDoctorId != null, // Make read-only if doctor is pre-selected
                decoration: InputDecoration(
                  hintText: "Enter Doctor Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF1565C0)),
                  filled: selectedDoctorId != null,
                  fillColor: selectedDoctorId != null ? Colors.grey[100] : Colors.transparent,
                ),
                validator: (value) => value!.isEmpty ? "Enter doctor name" : null,
              ),

              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: brandBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: brandBlue.withOpacity(0.1)),
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
                          child: _methodCard("EasyPaisa", Colors.green, selectedMethod == 'EasyPaisa'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _methodCard("JazzCash", Colors.orange, selectedMethod == 'JazzCash'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _paymentNumberController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Doctor's Payment Number",
                        isDense: true,
                        prefixIcon: Icon(Icons.phone_android, size: 20,
                            color: selectedMethod == 'EasyPaisa' ? Colors.green : Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) => value!.isEmpty ? "Enter number" : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              const Text("Transaction Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _transactionIdController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Transaction ID",
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.tag, size: 20),
                ),
                validator: (value) => value!.isEmpty ? "Enter ID" : null,
              ),
              const SizedBox(height: 20),
              const Text("Payment Screenshot", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                  ),
                  child: _screenshotFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            Text("Upload Screenshot", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_screenshotFile!, fit: BoxFit.contain),
                        ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SUBMIT PAYMENT", 
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                selectedDoctorId != null 
                    ? "Payment History with ${_doctorNameController.text}" 
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
  }

  Widget _buildPaymentHistory() {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    // Create query filtered by patient AND specific doctor if available
    Query query = FirebaseFirestore.instance
          .collection('payments')
          .where('patientId', isEqualTo: currentUserId);
    
    if (selectedDoctorId != null) {
      query = query.where('doctorId', isEqualTo: selectedDoctorId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No relevant payment history found.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? 'Pending';
            
            Color statusColor = Colors.orange;
            if (status == 'Approved') statusColor = Colors.green;
            if (status == 'Rejected') statusColor = Colors.red;

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                FirebaseFirestore.instance.collection('payments').doc(doc.id).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment record deleted")),
                );
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
                    data['doctorName'] ?? "Doctor",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ID: ${data['transactionId']}"),
                      Text("${data['paymentMethod']} - ${data['paymentNumber']}"),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
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
      onTap: () => setState(() => selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, color: color, size: 18),
            const SizedBox(width: 8),
            Text(method, style: TextStyle(
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
