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
  
  String? selectedDoctorId;
  String? selectedDoctorName;
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
          selectedDoctorName = docSnap.data()?['name'] ?? "Doctor";
        });
      }
    } catch (e) {
      debugPrint("Error loading doctor details: $e");
    }
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
    if (selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a doctor")));
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
        'doctorName': selectedDoctorName,
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
        Navigator.pop(context);
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
    final user = FirebaseAuth.instance.currentUser;

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
              const SizedBox(height: 20),
              
              const Text("Select Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctor_requests')
                    .where('patientId', isEqualTo: user?.uid)
                    .where('status', isEqualTo: 'Approved')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  var docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return const Text("No approved doctors found.");

                  Map<String, String> uniqueDoctors = {};
                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String? dId = data['doctorId'];
                    String? dName = data['doctorName'];
                    if (dId != null && dName != null) {
                      uniqueDoctors[dId] = dName;
                    }
                  }

                  return DropdownButtonFormField<String>(
                    value: uniqueDoctors.containsKey(selectedDoctorId) ? selectedDoctorId : null,
                    hint: const Text("Choose Doctor"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                    ),
                    items: uniqueDoctors.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDoctorId = val;
                        selectedDoctorName = uniqueDoctors[val];
                      });
                    },
                  );
                },
              ),

              if (selectedDoctorId != null) ...[
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
                      Text("Payment info for $selectedDoctorName", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      
                      const Text("Payment Method", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                          labelText: "Doctor's Number",
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
                const Text("Submission Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                const SizedBox(height: 15),
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
                              Text("Select Screenshot", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_screenshotFile!, fit: BoxFit.contain),
                          ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SUBMIT PAYMENT", 
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodCard(String method, Color color, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, color: color, size: 18),
            const SizedBox(width: 6),
            Text(method, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.black54,
            )),
          ],
        ),
      ),
    );
  }
}
