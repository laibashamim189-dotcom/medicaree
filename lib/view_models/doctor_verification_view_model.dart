import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../models/doctor_verification_model.dart';

class DoctorVerificationViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? _certificateFile;
  bool _isSubmitting = false;

  File? get certificateFile => _certificateFile;
  bool get isSubmitting => _isSubmitting;
  User? get currentUser => _auth.currentUser;

  Stream<DoctorVerificationModel?> getUserVerificationStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? DoctorVerificationModel.fromFirestore(snapshot) : null);
  }

  Future<void> pickCertificate() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _certificateFile = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitLicense({
    required String licenseNumber,
    required String speciality,
    required String? existingCertUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not authenticated.");

    if (_certificateFile == null && (existingCertUrl == null || existingCertUrl.isEmpty)) {
      throw Exception("Please upload your Medical License Certificate image.");
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      String? imageUrl = existingCertUrl;
      if (_certificateFile != null) {
        imageUrl = await CloudinaryService.uploadImage(_certificateFile!);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'licenseNumber': licenseNumber.trim(),
        'speciality': speciality.trim(),
        'certificateUrl': imageUrl,
        'licenseStatus': 'PENDING',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}