import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactsViewModel extends ChangeNotifier {
  final String? patientId;
  final bool isReadOnly;

  late String effectivePatientId;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  EmergencyContactsViewModel({this.patientId, this.isReadOnly = false}) {
    effectivePatientId = patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  // Stream for real-time contact updates
  Stream<List<EmergencyContactModel>> get contactsStream {
    if (effectivePatientId.isEmpty) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(effectivePatientId)
        .collection('emergency_contacts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => EmergencyContactModel.fromFirestore(doc)).toList());
  }

  // Phone Call Logic
  Future<String?> makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        return null;
      } else {
        return "Could not initiate call";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  // Add Contact Logic
  Future<String?> addContact() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      return "Please fill all fields";
    }
    if (RegExp(r'^[0-9]+$').hasMatch(name)) {
      return "Name cannot be numeric alone";
    }

    try {
      final contact = EmergencyContactModel(id: '', name: name, phone: phone);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(effectivePatientId)
          .collection('emergency_contacts')
          .add(contact.toMap());

      clearControllers();
      return null; // Success
    } catch (e) {
      return "Failed to add contact: $e";
    }
  }

  // Delete Contact Logic
  Future<void> deleteContact(String contactId) async {
    if (isReadOnly) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(effectivePatientId)
        .collection('emergency_contacts')
        .doc(contactId)
        .delete();
  }

  void clearControllers() {
    nameController.clear();
    phoneController.clear();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}