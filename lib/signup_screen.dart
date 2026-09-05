import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main.dart';

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
  
  String? selectedGender;
  String? selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final List<String> roles = ['Patient', 'Caregiver', 'Doctor'];

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;
      try {
        // 1. Create User in Firebase Auth
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If user exists in Auth but profile was missing in Firestore, we sign in to complete it
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          rethrow;
        }
      }

      // 2. Save Additional Data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': selectedRole,
        'gender': selectedGender,
        'dob': _dobController.text.trim(),
        'createdAt': DateTime.now(),
      });

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

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Account"), 
        backgroundColor: brandBlue, 
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 80, color: brandBlue),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                value: selectedRole,
                hint: const Text("Select Your Role"),
                decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.assignment_ind)),
                items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => selectedRole = val),
                validator: (value) => value == null ? 'Please select a role' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter your full name';
                  if (value.trim().length < 3) return 'Name must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter your email';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) return 'Enter a valid email (e.g., user@example.com)';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: "Date of Birth (YYYY-MM-DD)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter date of birth';
                  final dobRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dobRegex.hasMatch(value)) return 'Enter date in YYYY-MM-DD format';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedGender,
                hint: const Text("Select Gender"),
                decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.wc)),
                items: ["Male", "Female", "Other"].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                onChanged: (val) => setState(() => selectedGender = val),
                validator: (value) => value == null ? 'Please select gender' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password", 
                  border: const OutlineInputBorder(), 
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: brandBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter a password';
                  if (value.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: brandBlue),
                onPressed: _signUp,
                child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text("Already have an account? Login", style: TextStyle(color: brandBlue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
