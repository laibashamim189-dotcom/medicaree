import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'caregiver_dashboard.dart';
import 'cloudinary_service.dart';

class NurseLicenseUploadScreen extends StatefulWidget {
  const NurseLicenseUploadScreen({super.key});

  @override
  State<NurseLicenseUploadScreen> createState() => _NurseLicenseUploadScreenState();
}

class _NurseLicenseUploadScreenState extends State<NurseLicenseUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nursingLicenseController = TextEditingController();
  
  File? _certificateFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nursingLicenseController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _certificateFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _submitLicense() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final existingUrl = doc.data()?['certificateUrl'];

    if (_certificateFile == null && (existingUrl == null || existingUrl.toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your Nursing License Certificate image")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl = existingUrl;
      if (_certificateFile != null) {
        imageUrl = await CloudinaryService.uploadImage(_certificateFile!);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nursingLicenseNumber': _nursingLicenseController.text.trim(),
        'certificateUrl': imageUrl,
        'licenseStatus': 'PENDING',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credentials submitted for approval.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("User profile not found")));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String status = (userData['licenseStatus'] ?? 'NOT_SUBMITTED').toString().toUpperCase().trim();
        final String? existingCertUrl = userData['certificateUrl'];
        
        if (_nursingLicenseController.text.isEmpty && userData['nursingLicenseNumber'] != null) {
          _nursingLicenseController.text = userData['nursingLicenseNumber'];
        }

        if (status == 'APPROVED') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
              );
            }
          });
        }

        bool isEditable = status == 'NOT_SUBMITTED' || status == 'REJECTED';

        return Scaffold(
          appBar: AppBar(
            title: const Text("Nurse Verification"),
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.verified_user, size: 80, color: brandBlue),
                  const SizedBox(height: 10),
                  Text(
                    "Verification Status: $status",
                    style: TextStyle(
                      color: status == 'APPROVED' ? Colors.green : (status == 'REJECTED' ? Colors.red : Colors.orange),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your status will update automatically once the admin reviews your nursing credentials and certificate.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nursingLicenseController,
                    enabled: isEditable,
                    decoration: const InputDecoration(labelText: "Nursing License Number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter license number' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  const Align(alignment: Alignment.centerLeft, child: Text("Nursing License Certificate Copy", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  
                  GestureDetector(
                    onTap: isEditable ? _pickCertificate : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: _certificateFile != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_certificateFile!, fit: BoxFit.contain))
                          : (existingCertUrl != null && existingCertUrl.isNotEmpty
                              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(existingCertUrl, fit: BoxFit.contain))
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text("Select Certificate Image", style: TextStyle(color: Colors.grey)),
                                  ],
                                )),
                    ),
                  ),

                  const SizedBox(height: 25),
                  
                  if (status == 'PENDING')
                    _buildStatusCard(Colors.orangeAccent, Icons.hourglass_empty, "Verification Pending. Admin is reviewing your credentials."),
                  
                  if (status == 'REJECTED')
                    _buildStatusCard(Colors.redAccent, Icons.error_outline, "Rejected. Please check your details and certificate, then resubmit."),

                  if (isEditable)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitLicense,
                        style: ElevatedButton.styleFrom(backgroundColor: brandBlue, minimumSize: const Size(double.infinity, 55)),
                        child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit for Approval", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(Color color, IconData icon, String message) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 15),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}
