import 'package:flutter/material.dart';
import 'caregiver_dashboard.dart';
import 'login_screen.dart';
import '../models/nurse_license_model.dart';
import '../view_models/nurse_license_view_model.dart';

class NurseLicenseUploadScreen extends StatefulWidget {
  const NurseLicenseUploadScreen({super.key});

  @override
  State<NurseLicenseUploadScreen> createState() => _NurseLicenseUploadScreenState();
}

class _NurseLicenseUploadScreenState extends State<NurseLicenseUploadScreen> {
  late final NurseLicenseViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nursingLicenseController = TextEditingController();

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = NurseLicenseViewModel();
  }

  @override
  void dispose() {
    _nursingLicenseController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleSubmission(NurseLicenseModel license) async {
    if (!_formKey.currentState!.validate()) return;

    final errorMessage = await _viewModel.submitLicense(
      licenseNumber: _nursingLicenseController.text,
      existingUrl: license.certificateUrl,
    );

    if (mounted) {
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credentials submitted for approval.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.currentUser == null) return const LoginScreen();

    return StreamBuilder<NurseLicenseModel?>(
      stream: _viewModel.userLicenseStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final license = snapshot.data;
        if (license == null) {
          return const Scaffold(body: Center(child: Text("User profile not found")));
        }

        if (_nursingLicenseController.text.isEmpty && license.licenseNumber.isNotEmpty) {
          _nursingLicenseController.text = license.licenseNumber;
        }

        if (license.isApproved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
              );
            }
          });
        }

        return ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Nurse Verification"),
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
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
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user, size: 80, color: brandBlue),
                      const SizedBox(height: 10),
                      Text(
                        "Verification Status: ${license.status}",
                        style: TextStyle(
                          color: license.isApproved
                              ? Colors.green
                              : (license.isRejected ? Colors.red : Colors.orange),
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
                        enabled: license.isEditable,
                        decoration: const InputDecoration(
                          labelText: "Nursing License Number",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) =>
                        (value == null || value.isEmpty) ? 'Enter license number' : null,
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Nursing License Certificate Copy",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: license.isEditable ? _viewModel.pickCertificate : null,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: _viewModel.certificateFile != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_viewModel.certificateFile!, fit: BoxFit.contain),
                          )
                              : (license.certificateUrl != null && license.certificateUrl!.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(license.certificateUrl!, fit: BoxFit.contain),
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
                      if (license.isPending)
                        _buildStatusCard(
                          Colors.orangeAccent,
                          Icons.hourglass_empty,
                          "Verification Pending. Admin is reviewing your credentials.",
                        ),
                      if (license.isRejected)
                        _buildStatusCard(
                          Colors.redAccent,
                          Icons.error_outline,
                          "Rejected. Please check your details and certificate, then resubmit.",
                        ),
                      if (license.isEditable)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            onPressed: _viewModel.isSubmitting ? null : () => _handleSubmission(license),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandBlue,
                              minimumSize: const Size(double.infinity, 55),
                            ),
                            child: _viewModel.isSubmitting
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
