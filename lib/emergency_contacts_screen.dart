import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ListTile(
            leading: Icon(Icons.phone, color: Colors.red),
            title: Text("Ambulance"),
            subtitle: Text("1122"),
          ),
          ListTile(
            leading: Icon(Icons.contact_phone, color: Colors.blue),
            title: Text("Primary Caregiver"),
            subtitle: Text("+1 234 567 890"),
          ),
        ],
      ),
    );
  }
}