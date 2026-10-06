import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/doctor_review_model.dart';

class DoctorReviewViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSubmitting = false;
  bool _isEditMode = false;
  bool _isLoading = false;

  bool get isSubmitting => _isSubmitting;
  bool get isEditMode => _isEditMode;
  bool get isLoading => _isLoading;

  Future<DoctorReviewRecommendation?> fetchExistingData({
    required String collectionName,
    required String appointmentId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      DocumentSnapshot doc = await _firestore
          .collection(collectionName)
          .doc(appointmentId)
          .get();

      if (doc.exists) {
        final reviewData = DoctorReviewData.fromFirestore(doc);
        if (reviewData.isApproved) {
          _isEditMode = true;
          return reviewData.recommendations;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching existing doctor review data: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitRecommendation({
    required String collectionName,
    required String appointmentId,
    required String? patientId,
    required DoctorReviewRecommendation recommendations,
  }) async {
    if (patientId == null || patientId.isEmpty) {
      throw Exception("Patient ID not found.");
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final String currentDoctorId = _auth.currentUser?.uid ?? "";

      Map<String, dynamic> updateData = {
        'status': 'Approved',
        'doctorId': currentDoctorId,
        'recommendations': recommendations.toMap(),
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        updateData['isEdited'] = true;
        updateData['lastEditedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(collectionName)
          .doc(appointmentId)
          .update(updateData);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
