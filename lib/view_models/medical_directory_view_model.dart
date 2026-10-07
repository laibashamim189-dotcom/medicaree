import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medical_directory_model.dart';
import '../services/notification_service.dart';

class MedicalDirectoryViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late String effectivePatientId;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  bool isLoading = false;

  void init(String? patientId) {
    effectivePatientId = patientId ?? currentUserId;
  }
  Stream<List<MedicalItemModel>> getAppointmentsStream() {
    return _db
        .collection('reminders')
        .where('userId', isEqualTo: effectivePatientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .where((d) => d['type'] == 'appointment')
        .map((doc) => MedicalItemModel.fromFirestore(doc, 'appointment'))
        .toList());
  }

  Stream<List<MedicalItemModel>> getDoctorRequestsStream() {
    return _db
        .collection('doctor_requests')
        .where('patientId', isEqualTo: effectivePatientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MedicalItemModel.fromFirestore(doc, 'doctor_request'))
        .toList());
  }

  Stream<List<MedicalItemModel>> getCaregiverRequestsStream() {
    return _db
        .collection('caregiver_requests')
        .where('patientId', isEqualTo: effectivePatientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MedicalItemModel.fromFirestore(doc, 'caregiver_request'))
        .toList());
  }

  Future<bool> sendDoctorRequest({
    required String doctorName,
    required String doctorEmail,
    required String specialty,
    required String symptoms,
  }) async {
    _setLoading(true);
    try {
      String patientName = await _getPatientName();
      await _db.collection('doctor_requests').add({
        'patientId': effectivePatientId,
        'patientName': patientName,
        'doctorName': doctorName,
        'doctorEmail': doctorEmail,
        'specialty': specialty,
        'symptoms': symptoms,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }
  Future<bool> sendCaregiverRequest({
    required String cgName,
    required String cgEmail,
    required String relation,
  }) async {
    _setLoading(true);
    try {
      String patientName = await _getPatientName();
      await _db.collection('caregiver_requests').add({
        'patientId': effectivePatientId,
        'patientName': patientName,
        'caregiverName': cgName,
        'caregiverEmail': cgEmail,
        'relationship': relation,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }
  Future<bool> saveAppointment({
    required String doctorName,
    required String specialty,
    required String dateText,
    required String timeText,
    required DateTime? selectedDate,
    required TimeOfDay? selectedTime,
  }) async {
    if (selectedDate == null || selectedTime == null) return false;
    _setLoading(true);

    try {
      final docRef = await _db.collection('reminders').add({
        'userId': effectivePatientId,
        'title': "Appt: $doctorName",
        'doctorName': doctorName,
        'specialty': specialty,
        'type': 'appointment',
        'date': dateText,
        'time': timeText,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final scheduleTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: "Appointment Reminder",
        body: "Meeting with $doctorName at $timeText",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'appointment',
        userId: effectivePatientId,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }
  Future<void> deleteItem(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }
  Future<String> _getPatientName() async {
    final doc = await _db.collection('users').doc(effectivePatientId).get();
    return doc.exists ? (doc.data()?['name'] ?? 'Patient') : 'Patient';
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}