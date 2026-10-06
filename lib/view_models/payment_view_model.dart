import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../models/payment_model.dart';

class PaymentViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController paymentNumberController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();

  String? selectedDoctorId;
  String selectedMethod = 'EasyPaisa';
  File? screenshotFile;
  bool isSubmitting = false;

  User? get currentUser => _auth.currentUser;

  void initialize(String? initialDoctorId) {
    if (initialDoctorId != null) {
      selectedDoctorId = initialDoctorId;
      loadDoctorName(initialDoctorId);
    }
  }

  void setSelectedMethod(String method) {
    selectedMethod = method;
    notifyListeners();
  }

  Future<void> loadDoctorName(String docId) async {
    try {
      var docSnap = await _firestore.collection('users').doc(docId).get();
      if (docSnap.exists) {
        doctorNameController.text = docSnap.data()?['name'] ?? "";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading doctor details: $e");
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      screenshotFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<String?> submitPayment() async {
    final String doctorName = doctorNameController.text.trim();
    if (doctorName.isEmpty) {
      return "Please enter doctor name";
    }

    if (screenshotFile == null) {
      return "Please upload payment screenshot";
    }

    isSubmitting = true;
    notifyListeners();

    try {
      String? imageUrl = await CloudinaryService.uploadImage(screenshotFile!);
      if (imageUrl == null) {
        throw Exception("Upload failed");
      }

      final user = currentUser;
      final patientDoc = await _firestore.collection('users').doc(user?.uid).get();
      final patientName = patientDoc.exists ? (patientDoc.data()?['name'] ?? "Patient") : "Patient";

      final paymentRecord = PaymentRecord(
        id: '',
        patientId: user?.uid ?? '',
        patientName: patientName,
        doctorId: selectedDoctorId,
        doctorName: doctorName,
        transactionId: transactionIdController.text.trim(),
        paymentNumber: paymentNumberController.text.trim(),
        paymentMethod: selectedMethod,
        screenshotUrl: imageUrl,
        status: 'Pending',
      );

      await _firestore.collection('payments').add(paymentRecord.toMap());

      transactionIdController.clear();
      paymentNumberController.clear();
      screenshotFile = null;

      return null; // Return null on success
    } catch (e) {
      return "Error: ${e.toString()}";
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Stream<List<PaymentRecord>> getPaymentHistoryStream() {
    final String currentUserId = currentUser?.uid ?? "";

    Query query = _firestore
        .collection('payments')
        .where('patientId', isEqualTo: currentUserId);

    if (selectedDoctorId != null) {
      query = query.where('doctorId', isEqualTo: selectedDoctorId);
    }

    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PaymentRecord.fromFirestore(doc)).toList());
  }

  Future<void> deletePaymentRecord(String docId) async {
    await _firestore.collection('payments').doc(docId).delete();
  }

  @override
  void dispose() {
    transactionIdController.dispose();
    paymentNumberController.dispose();
    doctorNameController.dispose();
    super.dispose();
  }
}