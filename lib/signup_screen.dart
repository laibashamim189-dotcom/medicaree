import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main.dart';
import 'notification_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specialityController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  final _pharmacyAddressController = TextEditingController();
  final _drugLicenseController = TextEditingController();
  final _pharmacistRegController = TextEditingController();
  final _nursingLicenseController = TextEditingController();
  
  String? selectedGender;
  String? selectedRole;
  String? selectedCaregiverType;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final List<String> roles = ['Patient', 'Caregiver', 'Doctor', 'Pharmacist'];

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          rethrow;
        }
      }

      bool isNurse = selectedRole == 'Caregiver' && selectedCaregiverType == 'Nurse';

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': selectedRole,
        'gender': selectedGender,
        'dob': _dobController.text.trim(),
        'createdAt': DateTime.now(),
        'licenseStatus': (selectedRole == 'Doctor' || selectedRole == 'Pharmacist' || isNurse) ? 'NOT_SUBMITTED' : 'APPROVED',
      };

      if (selectedRole == 'Caregiver') {
        userData['caregiverType'] = selectedCaregiverType;
        if (isNurse) {
          userData['nursingLicenseNumber'] = _nursingLicenseController.text.trim();
        }
      }

      if (selectedRole == 'Doctor') {
        userData['licenseNumber'] = _licenseController.text.trim();
        userData['speciality'] = _specialityController.text.trim();
      }

      if (selectedRole == 'Pharmacist') {
        userData['pharmacyName'] = _pharmacyNameController.text.trim();
        userData['pharmacyAddress'] = _pharmacyAddressController.text.trim();
        userData['drugLicenseNumber'] = _drugLicenseController.text.trim();
        userData['pharmacistRegNumber'] = _pharmacistRegController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

      // Save FCM Token for Notifications
      await NotificationService.updateFCMToken();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RoleWrapper(role: selectedRole!)),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Registration Failed")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
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
    const Color brandBlue = Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: brandBlue,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60), // Icon moved up
                // Clean Logo section
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
                // Signup card
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
                          value: selectedRole,
                          hint: const Text("Select Your Role"),
                          decoration: _inputDecoration("Select Your Role", Icons.assignment_ind),
                          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) => setState(() {
                            selectedRole = val;
                            selectedCaregiverType = null;
                          }),
                          validator: (value) => value == null ? 'Please select a role' : null,
                        ),
                        const SizedBox(height: 15),

                        if (selectedRole == 'Caregiver') ...[
                          DropdownButtonFormField<String>(
                            value: selectedCaregiverType,
                            hint: const Text("Select Caregiver Type"),
                            decoration: _inputDecoration("Select Caregiver Type", Icons.people_outline),
                            items: ['Nurse', 'Friend', 'Relative'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                            onChanged: (val) => setState(() => selectedCaregiverType = val),
                            validator: (value) => value == null ? 'Please select caregiver type' : null,
                          ),
                          const SizedBox(height: 15),
                          if (selectedCaregiverType == 'Nurse') ...[
                            TextFormField(
                              controller: _nursingLicenseController,
                              decoration: _inputDecoration("Nursing License Number", Icons.badge),
                              validator: (value) => (value == null || value.isEmpty) ? 'Enter license number' : null,
                            ),
                            const SizedBox(height: 15),
                          ],
                        ],

                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration("Full Name", Icons.person),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter full name';
                            if (RegExp(r'^[0-9]+$').hasMatch(value.trim())) return 'Cannot be numeric alone';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Email Address", Icons.email),
                          validator: (value) {
                            if (value == null || !value.endsWith('@gmail.com')) return 'Must end with @gmail.com';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        TextFormField(
                          controller: _dobController,
                          decoration: _inputDecoration("DOB (YYYY-MM-DD)", Icons.calendar_today),
                          validator: (value) => (value == null || value.isEmpty) ? 'Enter date of birth' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          hint: const Text("Select Gender"),
                          decoration: _inputDecoration("Select Gender", Icons.wc),
                          items: ["Male", "Female", "Other"].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                          onChanged: (val) => setState(() => selectedGender = val),
                          validator: (value) => value == null ? 'Select gender' : null,
                        ),
                        const SizedBox(height: 15),

                        if (selectedRole == 'Doctor') ...[
                          TextFormField(
                            controller: _specialityController,
                            decoration: _inputDecoration("Speciality", Icons.medical_services),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter speciality' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _licenseController,
                            decoration: _inputDecoration("License Number", Icons.badge),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter license number' : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        if (selectedRole == 'Pharmacist') ...[
                          TextFormField(
                            controller: _pharmacyNameController,
                            decoration: _inputDecoration("Pharmacy Name", Icons.local_pharmacy),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter pharmacy name' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _pharmacyAddressController,
                            decoration: _inputDecoration("Pharmacy Address", Icons.map),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter address' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _drugLicenseController,
                            decoration: _inputDecoration("Drug License Number", Icons.description),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter license' : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline, color: brandBlue),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: brandBlue),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: const Color(0xFFF3F6F9),
                          ),
                          validator: (value) => (value == null || value.length < 8) ? 'Minimum 8 characters' : null,
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 58),
                            backgroundColor: brandBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: _signUp,
                          child: const Text("SIGN UP", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
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
          ),
    );
  }
}
