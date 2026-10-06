import 'package:flutter/material.dart';
import '../models/emergency_contact_model.dart';
import '../view_models/emergency_contacts_view_model.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;

  const EmergencyContactsScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late EmergencyContactsViewModel _viewModel;
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = EmergencyContactsViewModel(
      patientId: widget.patientId,
      isReadOnly: widget.isReadOnly,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleMakeCall(String phone) async {
    String? error = await _viewModel.makeCall(phone);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _showManualAddDialog() {
    if (widget.isReadOnly) return;
    _viewModel.clearControllers();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Emergency Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _viewModel.nameController,
              decoration: const InputDecoration(labelText: "Name", hintText: "e.g. Ambulance"),
            ),
            TextField(
              controller: _viewModel.phoneController,
              decoration: const InputDecoration(labelText: "Phone Number", hintText: "e.g. 1122"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              String? error = await _viewModel.addContact();
              if (error != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                }
              } else {
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
    if (_viewModel.effectivePatientId.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not identified")));
    }

    return StreamBuilder<List<EmergencyContactModel>>(
      stream: _viewModel.contactsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final contacts = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Emergency Contacts", style: TextStyle(color: Colors.white)),
            backgroundColor: brandBlue,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              bool isAmbulance = contact.name.toLowerCase().contains('ambulance');

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: Icon(
                  isAmbulance ? Icons.phone : Icons.account_box,
                  color: isAmbulance ? Colors.red : Colors.blue,
                  size: 30,
                ),
                title: Text(contact.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text(contact.phone, style: const TextStyle(color: Colors.black54)),
                onTap: () => _handleMakeCall(contact.phone),
                trailing: widget.isReadOnly
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _viewModel.deleteContact(contact.id),
                ),
              );
            },
          ),
          floatingActionButton: widget.isReadOnly
              ? null
              : FloatingActionButton(
            onPressed: _showManualAddDialog,
            backgroundColor: brandBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    backgroundColor: brandBlue,
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