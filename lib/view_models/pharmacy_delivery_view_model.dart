import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pharmacy_delivery_model.dart';

class PharmacyDeliveryViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSendingRequest = false;
  bool get isSendingRequest => _isSendingRequest;

  late String _effectivePatientId;
  String get effectivePatientId => _effectivePatientId;

  void init(String? patientId) {
    _effectivePatientId = patientId ?? _auth.currentUser?.uid ?? "";
  }
  String? validateForm({
    required String name,
    required String quantityStr,
    required String pName,
    required String pAddress,
    required String pEmail,
    required String pPhone,
  }) {
    if (name.isEmpty || quantityStr.isEmpty || pName.isEmpty || pAddress.isEmpty || pEmail.isEmpty || pPhone.isEmpty) {
      return "Please fill all details";
    }
    if (RegExp(r'^[0-9]+$').hasMatch(name)) {
      return "Medicine name cannot be numeric alone";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(quantityStr)) {
      return "Quantity must be numeric";
    }
    if (RegExp(r'^[0-9]+$').hasMatch(pName)) {
      return "Pharmacy name cannot be numeric alone";
    }
    if (!pEmail.contains('@') || !pEmail.contains('.') || !pEmail.endsWith('@gmail.com')) {
      return "Invalid email: must be in name@gmail.com format";
    }
    final emailNamePart = pEmail.split('@')[0];
    if (RegExp(r'^[0-9]+$').hasMatch(emailNamePart)) {
      return "Email prefix cannot be numeric alone";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(pPhone)) {
      return "Phone number must be numeric";
    }
    return null;
  }

  // Send Availability Request
  Future<bool> sendAvailabilityRequest({
    required String name,
    required String quantityStr,
    required String pName,
    required String pAddress,
    required String pEmail,
    required String pPhone,
    required Function(String) onError,
  }) async {
    final validationError = validateForm(
      name: name,
      quantityStr: quantityStr,
      pName: pName,
      pAddress: pAddress,
      pEmail: pEmail,
      pPhone: pPhone,
    );

    if (validationError != null) {
      onError(validationError);
      return false;
    }

    _isSendingRequest = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final int quantity = int.tryParse(quantityStr) ?? 1;

      await _firestore.collection('medicine_orders').add({
        'userId': _effectivePatientId,
        'userEmail': user.email,
        'patientPhone': pPhone,
        'medicineName': name,
        'quantity': quantity,
        'pharmacyName': pName,
        'pharmacyAddress': pAddress,
        'pharmacyManagerEmail': pEmail.toLowerCase().trim(),
        'deliveryStatus': 'Pending (Awaiting Confirmation)',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      onError("Failed to send request: $e");
      return false;
    } finally {
      _isSendingRequest = false;
      notifyListeners();
    }
  }
  Stream<List<MedicineOrderModel>> getOrdersStream() {
    return _firestore
        .collection('medicine_orders')
        .where('userId', isEqualTo: _effectivePatientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MedicineOrderModel.fromFirestore(doc)).toList());
  }
  Future<void> confirmDeliveryAddress(String orderId, String address) async {
    if (address.trim().isEmpty) return;
    await _firestore.collection('medicine_orders').doc(orderId).update({
      'deliveryAddress': address.trim(),
      'deliveryStatus': 'Delivery Requested',
    });
  }

  // Delete Order
  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('medicine_orders').doc(orderId).delete();
  }

  // Helper for UI status color
  Color getStatusColor(String status) {
    if (status.contains('In Stock')) return Colors.blue;
    if (status.contains('Requested')) return Colors.green;
    if (status.contains('Rejected') || status.contains('Out of Stock')) return Colors.red;
    return Colors.orange;
  }
}