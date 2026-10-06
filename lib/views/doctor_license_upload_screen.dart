import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor_verification_model.dart';
import '../view_models/doctor_verification_view_model.dart';
import 'doctor_dashboard.dart';
import 'login_screen.dart';

class DoctorLicenseUploadScreen extends StatefulWidget {
  const DoctorLicenseUploadScreen({super.key});

  @override
  State<DoctorLicenseUploadScreen> createState() => _DoctorLicenseUploadScreenState();
}

class _DoctorLicenseUploadScreenState extends State<DoctorLicenseUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _specialityController = TextEditingController();

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void dispose() {
    _licenseController.dispose();
    _specialityController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handlePickImage(DoctorVerificationViewModel viewModel) async {
    try {
      await viewModel.pickCertificate();
    } catch (e) {
      _showSnackBar("Error picking image: $e");
    }
  }

  Future<void> _handleSubmit(DoctorVerificationViewModel viewModel, String? existingCertUrl) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await viewModel.submitLicense(
        licenseNumber: _licenseController.text,
        speciality: _specialityController.text,
        existingCertUrl: existingCertUrl,
      );
      _showSnackBar("Credentials submitted for approval.");
    } catch (e) {
      _showSnackBar(e.toString().replaceAll("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DoctorVerificationViewModel>(context);

    if (viewModel.currentUser == null) {
      return const LoginScreen();
    }

    return StreamBuilder<DoctorVerificationModel?>(
      stream: viewModel.getUserVerificationStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final verificationData = snapshot.data;
        if (verificationData == null) {
          return const Scaffold(body: Center(child: Text("User profile not found.")));
        }

        if (_licenseController.text.isEmpty && verificationData.licenseNumber.isNotEmpty) {
          _licenseController.text = verificationData.licenseNumber;
        }
        if (_specialityController.text.isEmpty && verificationData.speciality.isNotEmpty) {
          _specialityController.text = verificationData.speciality;
        }

        if (verificationData.licenseStatus == 'APPROVED') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DoctorDashboard()),
              );
            }
          });
        }

        final status = verificationData.licenseStatus;
        final isEditable = verificationData.isEditable;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Medical Verification"),
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await viewModel.signOut();
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
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.verified_user, size: 80, color: brandBlue),
                  const SizedBox(height: 15),
                  Text(
                    "Verification Status: $status",
                    style: TextStyle(
                      color: status == 'APPROVED'
                          ? Colors.green
                          : (status == 'REJECTED' ? Colors.red : Colors.orange),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Admin will review your medical credentials and certificate copy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _specialityController,
                    enabled: isEditable,
                    decoration: const InputDecoration(
                      labelText: "Speciality",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Enter speciality' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _licenseController,
                    enabled: isEditable,
                    decoration: const InputDecoration(
                      labelText: "PMDC / License Number",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Enter license number' : null,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Medical License Certificate Copy", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: isEditable ? () => _handlePickImage(viewModel) : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: viewModel.certificateFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(viewModel.certificateFile!, fit: BoxFit.contain),
                      )
                          : (verificationData.certificateUrl != null && verificationData.certificateUrl!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(verificationData.certificateUrl!, fit: BoxFit.contain),
                      )
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
                        onPressed: viewModel.isSubmitting ? null : () => _handleSubmit(viewModel, verificationData.certificateUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          minimumSize: const Size(double.infinity, 55),
                        ),
                        child: viewModel.isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Submit for Approval", style: TextStyle(color: Colors.white, fontSize: 16)),
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