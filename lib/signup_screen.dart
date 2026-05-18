import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Theme: White
      appBar: AppBar(title: const Text("Create Account"), backgroundColor: Colors.blue), // Theme: Blue
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(decoration: const InputDecoration(labelText: "Full Name")),
              TextFormField(decoration: const InputDecoration(labelText: "Email")),
              TextFormField(decoration: const InputDecoration(labelText: "Date of Birth (YYYY-MM-DD)")),
              DropdownButtonFormField<String>(
                value: selectedGender,
                hint: const Text("Select Gender"),
                items: ["Male", "Female", "Other"].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                onChanged: (val) => setState(() => selectedGender = val),
              ),
              TextFormField(obscureText: true, decoration: const InputDecoration(labelText: "Password")), // Min 8 chars [cite: 111]
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
                onPressed: () { /* Logic for Firebase signup Algorithm 2 [cite: 306] */ },
                child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}