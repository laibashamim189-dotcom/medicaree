import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const EmergencyContactsScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not initiate call")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showManualAddDialog() {
    if (widget.isReadOnly) return;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Emergency Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name", hintText: "e.g. Ambulance"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number", hintText: "e.g. 1122"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_effectivePatientId)
                    .collection('emergency_contacts')
                    .add({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_effectivePatientId.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not identified")));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_effectivePatientId)
          .collection('emergency_contacts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Emergency Contacts", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1565C0),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var contact = snapshot.data!.docs[index];
              var data = contact.data() as Map<String, dynamic>;
              String name = data['name'] ?? '';
              
              bool isAmbulance = name.toLowerCase().contains('ambulance');

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: Icon(
                  isAmbulance ? Icons.phone : Icons.account_box, 
                  color: isAmbulance ? Colors.red : Colors.blue,
                  size: 30,
                ),
                title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text(data['phone'] ?? '', style: const TextStyle(color: Colors.black54)),
                onTap: () => _makeCall(data['phone']),
                trailing: widget.isReadOnly 
                  ? null 
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => contact.reference.delete(),
                    ),
              );
            },
          ),
          floatingActionButton: widget.isReadOnly ? null : FloatingActionButton(
            onPressed: _showAddManualDialog,
            backgroundColor: const Color(0xFF634D1F),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showAddManualDialog() => _showManualAddDialog();

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Emergency\ncontacts",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w400, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.contact_phone_outlined, size: 80, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "No emergency contacts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 25),
              if (!widget.isReadOnly)
                ElevatedButton.icon(
                  onPressed: _showManualAddDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add contact", style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF634D1F),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              const SizedBox(height: 60),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 24, color: Colors.black54),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "To help in an emergency, people can view and call these contacts without unlocking your device.",
                      style: TextStyle(color: Colors.black87.withValues(alpha: 0.7), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
