import 'package:flutter/material.dart';

class CaregiverRequestScreen extends StatefulWidget {
  const CaregiverRequestScreen({super.key});

  @override
  State<CaregiverRequestScreen> createState() => _CaregiverRequestScreenState();
}

class _CaregiverRequestScreenState extends State<CaregiverRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _relation = 'Relative';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Request"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Who is your Caregiver?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Caregiver Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? "Please enter a name" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _relation,
                decoration: const InputDecoration(
                  labelText: "Relationship",
                  border: OutlineInputBorder(),
                ),
                items: ['Relative', 'Professional Nurse', 'Friend', 'Other']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _relation = value!),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitRequest();
                  }
                },
                child: const Text(
                  "SEND REQUEST TO CAREGIVER",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRequest() {
    // Logic to save to Firebase would happen here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Sent!"),
        content: Text("A request has been sent to ${_nameController.text}. Wait for them to accept."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Go back to Dashboard
            },
            child: const Text("Back to Dashboard"),
          ),
        ],
      ),
    );
  }
}