import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../models/nurse_license_model.dart';

class NurseLicenseViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? certificateFile;
  bool isSubmitting = false;

  User? get currentUser => _auth.currentUser;

  Stream<NurseLicenseModel?> get userLicenseStream {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return NurseLicenseModel.fromFirestore(user.uid, snapshot.data());
    });
  }

  Future<void> pickCertificate() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        certificateFile = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String?> submitLicense({
    required String licenseNumber,
    required String? existingUrl,
  }) async {
    final user = currentUser;
    if (user == null) return "User session expired";

    if (certificateFile == null && (existingUrl == null || existingUrl.isEmpty)) {
      return "Please upload your Nursing License Certificate image";
    }

    isSubmitting = true;
    notifyListeners();

    try {
      String? imageUrl = existingUrl;
      if (certificateFile != null) {
        imageUrl = await CloudinaryService.uploadImage(certificateFile!);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'nursingLicenseNumber': licenseNumber.trim(),
        'certificateUrl': imageUrl,
        'licenseStatus': 'PENDING',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return "Error submitting credentials: $e";
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}