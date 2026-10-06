import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../main.dart';
import '../view_models/signup_view_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SignupViewModel _viewModel;

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = SignupViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final errorMessage = await _viewModel.signUp();

    if (!mounted) return;

    if (errorMessage == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RoleWrapper(role: _viewModel.selectedRole!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: brandBlue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F6F9),
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBlue,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo Section
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text(
                      "Please fill the details to continue",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Form Container
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: _viewModel.selectedRole,
                          hint: const Text("Select Your Role"),
                          decoration: _inputDecoration("Select Your Role", Icons.assignment_ind),
                          items: _viewModel.roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: _viewModel.setSelectedRole,
                          validator: (value) => value == null ? 'Please select a role' : null,
                        ),
                        const SizedBox(height: 15),

                        // Caregiver Dynamic Fields
                        if (_viewModel.selectedRole == 'Caregiver') ...[
                          DropdownButtonFormField<String>(
                            value: _viewModel.selectedCaregiverType,
                            hint: const Text("Select Caregiver Type"),
                            decoration: _inputDecoration("Select Caregiver Type", Icons.people_outline),
                            items: _viewModel.caregiverTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                            onChanged: _viewModel.setSelectedCaregiverType,
                            validator: (value) => value == null ? 'Please select caregiver type' : null,
                          ),
                          const SizedBox(height: 15),
                          if (_viewModel.selectedCaregiverType == 'Nurse') ...[
                            TextFormField(
                              controller: _viewModel.nursingLicenseController,
                              decoration: _inputDecoration("Nursing License Number", Icons.badge),
                              validator: (value) => (value == null || value.isEmpty) ? 'Enter license number' : null,
                            ),
                            const SizedBox(height: 15),
                          ],
                        ],

                        // Name Field
                        TextFormField(
                          controller: _viewModel.nameController,
                          decoration: _inputDecoration("Full Name", Icons.person),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter full name';
                            if (RegExp(r'^[0-9]+$').hasMatch(value.trim())) return 'Cannot be numeric alone';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Email Field
                        TextFormField(
                          controller: _viewModel.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Email Address", Icons.email),
                          validator: (value) {
                            if (value == null || !value.endsWith('@gmail.com')) return 'Must end with @gmail.com';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // DOB Field
                        TextFormField(
                          controller: _viewModel.dobController,
                          decoration: _inputDecoration("DOB (YYYY-MM-DD)", Icons.calendar_today),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter date of birth';
                            if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
                              return 'Use format YYYY-MM-DD (e.g. 1995-12-31)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Gender Field
                        DropdownButtonFormField<String>(
                          value: _viewModel.selectedGender,
                          hint: const Text("Select Gender"),
                          decoration: _inputDecoration("Select Gender", Icons.wc),
                          items: _viewModel.genders.map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                          onChanged: _viewModel.setSelectedGender,
                          validator: (value) => value == null ? 'Select gender' : null,
                        ),
                        const SizedBox(height: 15),

                        // Doctor Dynamic Fields
                        if (_viewModel.selectedRole == 'Doctor') ...[
                          TextFormField(
                            controller: _viewModel.specialityController,
                            decoration: _inputDecoration("Speciality", Icons.medical_services),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter speciality' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _viewModel.licenseController,
                            decoration: _inputDecoration("License Number", Icons.badge),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter license number' : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        // Pharmacist Dynamic Fields
                        if (_viewModel.selectedRole == 'Pharmacist') ...[
                          TextFormField(
                            controller: _viewModel.pharmacyNameController,
                            decoration: _inputDecoration("Pharmacy Name", Icons.local_pharmacy),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter pharmacy name' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _viewModel.pharmacyAddressController,
                            decoration: _inputDecoration("Pharmacy Address", Icons.map),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter address' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _viewModel.drugLicenseController,
                            decoration: _inputDecoration("Drug License Number", Icons.description),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter license' : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        // Password Field
                        TextFormField(
                          controller: _viewModel.passwordController,
                          obscureText: _viewModel.obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline, color: brandBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _viewModel.obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: brandBlue,
                              ),
                              onPressed: _viewModel.togglePasswordVisibility,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3F6F9),
                          ),
                          validator: (value) => (value == null || value.length < 8) ? 'Minimum 8 characters' : null,
                        ),
                        const SizedBox(height: 30),

                        // Signup Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 58),
                            backgroundColor: brandBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: _handleSignUp,
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // Login Option
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                      children: [
                        TextSpan(text: "Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
