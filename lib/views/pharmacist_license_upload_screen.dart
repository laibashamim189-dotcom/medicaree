import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'pharmacy_dashboard_screen.dart';
import '../models/pharmacist_license_model.dart';
import '../view_models/pharmacist_license_view_model.dart';

class PharmacistLicenseUploadScreen extends StatefulWidget {
  const PharmacistLicenseUploadScreen({super.key});

  @override
  State<PharmacistLicenseUploadScreen> createState() => _PharmacistLicenseUploadScreenState();
}

class _PharmacistLicenseUploadScreenState extends State<PharmacistLicenseUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PharmacistLicenseViewModel _viewModel;

  final Color brandBlue = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = PharmacistLicenseViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleImagePick() async {
    final error = await _viewModel.pickCertificate();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _handleSubmit(String? existingUrl) async {
    if (!_formKey.currentState!.validate()) return;

    final errorMessage = await _viewModel.submitLicense(existingUrl);

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Credentials submitted for approval.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.currentUser == null) return const LoginScreen();

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return StreamBuilder<PharmacistLicenseModel?>(
          stream: _viewModel.getLicenseStatusStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Scaffold(body: Center(child: Text("User profile not found")));
            }

            final licenseData = snapshot.data!;
            final String status = licenseData.licenseStatus;
            final String? existingCertUrl = licenseData.certificateUrl;

            if (status == 'APPROVED') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const PharmacyDashboard()),
                  );
                }
              });
            }

            bool isEditable = status == 'NOT_SUBMITTED' || status == 'REJECTED';

            return Scaffold(
              appBar: AppBar(
                title: const Text("Pharmacist Verification"),
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
                      Icon(Icons.verified_user, size: 80, color: brandBlue),
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
                        "Your status will update automatically once the admin reviews your pharmacy credentials and certificate.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _viewModel.pharmacyNameController,
                        enabled: isEditable,
                        decoration: const InputDecoration(
                          labelText: "Pharmacy Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_pharmacy),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _viewModel.pharmacyAddressController,
                        enabled: isEditable,
                        decoration: const InputDecoration(
                          labelText: "Pharmacy Address",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _viewModel.drugLicenseController,
                        enabled: isEditable,
                        decoration: const InputDecoration(
                          labelText: "Drug License Number",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _viewModel.pharmacistRegController,
                        enabled: isEditable,
                        decoration: const InputDecoration(
                          labelText: "Pharmacist Registration Number",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.how_to_reg),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Drug License Certificate Copy", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: isEditable ? _handleImagePick : null,
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
                              : (existingCertUrl != null && existingCertUrl.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(existingCertUrl, fit: BoxFit.contain),
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
                            onPressed: _viewModel.isSubmitting ? null : () => _handleSubmit(existingCertUrl),
                            style: ElevatedButton.styleFrom(backgroundColor: brandBlue, minimumSize: const Size(double.infinity, 55)),
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