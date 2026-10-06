import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/appointment_screen_model.dart';
import '../services/notification_service.dart';

class AppointmentScreenViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _effectivePatientId = '';
  String get effectivePatientId => _effectivePatientId;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  TimeOfDay? _selectedTime;
  TimeOfDay? get selectedTime => _selectedTime;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  void initPatientId(String? patientId) {
    _effectivePatientId = patientId ?? _auth.currentUser?.uid ?? "";
    _selectedDate = DateTime.now();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  TimeOfDay parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      var hour = int.parse(parts[0]);
      final minuteParts = parts[1].split(' ');
      final minute = int.parse(minuteParts[0]);
      final isPm = timeStr.toLowerCase().contains('pm');
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  Stream<List<AppointmentScreenModel>> getAppointmentsStream() {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: _effectivePatientId)
        .where('type', isEqualTo: 'appointment')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppointmentScreenModel.fromFirestore(doc))
        .toList());
  }

  Future<void> saveAppointment({
    required String doctorName,
    required String specialty,
    required String dateText,
    required String timeText,
    required VoidCallback onSuccess,
  }) async {
    if (_effectivePatientId.isEmpty || _selectedTime == null || _selectedDate == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      final appointment = AppointmentScreenModel(
        id: '',
        userId: _effectivePatientId,
        doctorName: doctorName.trim(),
        specialty: specialty.trim(),
        date: dateText,
        time: timeText,
      );

      final docRef = await _firestore.collection('reminders').add(appointment.toMap());

      DateTime scheduleTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: "Appointment Reminder",
        body: "Meeting with ${doctorName.trim()} at $timeText",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'appointment',
        userId: _effectivePatientId,
      );

      onSuccess();
    } catch (e) {
      debugPrint("Save Error: $e");
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateAppointment({
    required String docId,
    required String doctorName,
    required String specialty,
    required String dateText,
    required String timeText,
  }) async {
    try {
      await _firestore.collection('reminders').doc(docId).update({
        'title': "Appt: ${doctorName.trim()}",
        'doctorName': doctorName.trim(),
        'specialty': specialty.trim(),
        'date': dateText,
        'time': timeText,
      });

      if (_selectedDate != null && _selectedTime != null) {
        DateTime scheduleTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        await NotificationService.scheduleNotification(
          id: docId.hashCode,
          title: "Appointment Reminder",
          body: "Meeting with ${doctorName.trim()} at $timeText",
          scheduledDate: scheduleTime,
          docId: docId,
          type: 'appointment',
          userId: _effectivePatientId,
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  Future<void> deleteAppointment(String docId) async {
    try {
      await _firestore.collection('reminders').doc(docId).delete();
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }
}