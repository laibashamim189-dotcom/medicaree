import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/measurement_tracker_model.dart';

class MeasurementTrackerViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedCategory = 'Blood Pressure';
  final List<String> categories = [
    'Blood Pressure',
    'Body Weight',
    'Blood Sugar',
  ];

  String getEffectivePatientId(String? patientId) {
    return patientId ?? _auth.currentUser?.uid ?? "";
  }

  void setSelectedCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  Stream<List<MeasurementTrackerModel>> getMeasurementsStream(String patientId) {
    final effectiveId = getEffectivePatientId(patientId);
    return _firestore
        .collection('health_measurements')
        .where('patientId', isEqualTo: effectiveId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MeasurementTrackerModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> deleteMeasurement(String docId) async {
    await _firestore.collection('health_measurements').doc(docId).delete();
  }

  Future<String?> recordMeasurement({
    required String patientId,
    required String systolicText,
    required String diastolicText,
    required String valueText,
  }) async {
    final effectiveId = getEffectivePatientId(patientId);
    if (effectiveId.isEmpty) {
      return "Patient ID not found";
    }

    String displayValue = "";
    int? systolicValue;
    int? diastolicValue;

    if (selectedCategory == 'Blood Pressure') {
      final sStr = systolicText.trim();
      final dStr = diastolicText.trim();

      if (sStr.isEmpty || dStr.isEmpty) {
        return "Please fill all details";
      }

      final s = int.tryParse(sStr);
      final d = int.tryParse(dStr);

      if (s == null || d == null) {
        return "Error: Values must be in numeric form, not text. Please enter values in numbers.";
      }

      systolicValue = s;
      diastolicValue = d;
      displayValue = "$s/$d mmHg";
    } else {
      final vStr = valueText.trim();

      if (vStr.isEmpty) {
        return "Please enter value";
      }

      final v = double.tryParse(vStr);
      if (v == null) {
        return "Error: Value must be in numeric form, not text. Please enter values in numbers.";
      }

      String unit = selectedCategory == 'Body Weight' ? 'kg' : 'mg/dL';
      displayValue = "$vStr $unit";
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      await _firestore.collection('health_measurements').add({
        'patientId': effectiveId,
        'category': selectedCategory,
        'value': displayValue,
        'systolic': systolicValue,
        'diastolic': diastolicValue,
        'date': dateStr,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return null; // Success
    } catch (e) {
      return "Error saving: $e";
    }
  }
}