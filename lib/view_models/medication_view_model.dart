import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication_model.dart';
import '../services/notification_service.dart';

class MedicationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isSaving = false;
  String selectedFrequencyType = 'Everyday';
  String selectedFrequency = 'Once a day';
  List<DateTime> selectedDates = [];

  String getEffectivePatientId(String? patientId) {
    return patientId ?? _auth.currentUser?.uid ?? "";
  }

  void setFrequencyType(String value) {
    selectedFrequencyType = value;
    if (value == 'Once a day' || value == 'Twice a day' || value == '3 times a day') {
      selectedFrequency = value;
    }
    notifyListeners();
  }

  void setFrequency(String value) {
    selectedFrequency = value;
    notifyListeners();
  }

  void addSpecificDate(DateTime date) {
    if (!selectedDates.any((d) => DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(date))) {
      selectedDates.add(date);
      selectedDates.sort();
      notifyListeners();
    }
  }

  void removeSpecificDate(DateTime date) {
    selectedDates.remove(date);
    notifyListeners();
  }

  void clearSpecificDates() {
    selectedDates.clear();
    notifyListeners();
  }

  TimeOfDay parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(' ')[0]);
      final isPm = timeStr.toLowerCase().contains('pm');
      return TimeOfDay(
        hour: isPm && hour != 12 ? hour + 12 : (hour == 12 && !isPm ? 0 : hour),
        minute: minute,
      );
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  Stream<List<MedicationModel>> getMedicationsStream(String? patientId) {
    final effectiveId = getEffectivePatientId(patientId);

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: effectiveId)
        .where('type', isEqualTo: 'medication')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MedicationModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> deleteMedication(String docId) async {
    await _firestore.collection('reminders').doc(docId).delete();
  }

  Future<String?> saveMedication({
    required String? patientId,
    required String name,
    required String dosage,
    required String stock,
    required DateTime? selectedDate,
    required TimeOfDay? time1,
    required TimeOfDay? time2,
    required TimeOfDay? time3,
    required String time1Text,
    required String time2Text,
    required String time3Text,
  }) async {
    final effectiveId = getEffectivePatientId(patientId);
    if (effectiveId.isEmpty) return "User context not identified";

    List<DateTime> datesToProcess = [];
    if (selectedFrequencyType != 'Specific Dates') {
      if (selectedDate == null) return "Please select start date";
      datesToProcess.add(selectedDate);
    } else {
      if (selectedDates.isEmpty) return "Please select at least one date";
      datesToProcess.addAll(selectedDates);
    }

    List<TimeOfDay?> timesToSchedule = [time1];
    List<String> timeStrings = [time1Text];

    if (selectedFrequency == 'Twice a day') {
      timesToSchedule.add(time2);
      timeStrings.add(time2Text);
    } else if (selectedFrequency == '3 times a day') {
      timesToSchedule.add(time2);
      timeStrings.add(time2Text);
      timesToSchedule.add(time3);
      timeStrings.add(time3Text);
    }

    for (var t in timesToSchedule) {
      if (t == null) return "Please select all required times";
    }

    isSaving = true;
    notifyListeners();

    try {
      for (DateTime date in datesToProcess) {
        final String setDate = DateFormat('yyyy-MM-dd').format(date);

        String displayFreq = selectedFrequencyType;
        if (selectedFrequencyType == 'Everyday' || selectedFrequencyType == 'Specific Dates') {
          displayFreq = "$selectedFrequencyType ($selectedFrequency)";
        }

        final docRef = await _firestore.collection('reminders').add({
          'userId': effectiveId,
          'title': name,
          'dosage': dosage,
          'times': timeStrings,
          'date': setDate,
          'type': 'medication',
          'status': 'Pending',
          'frequency': displayFreq,
          'stock': stock,
          'timestamp': FieldValue.serverTimestamp(),
        });

        for (int i = 0; i < timesToSchedule.length; i++) {
          TimeOfDay currentT = timesToSchedule[i]!;
          DateTime scheduleTime = DateTime(date.year, date.month, date.day, currentT.hour, currentT.minute);

          await NotificationService.scheduleNotification(
            id: (docRef.id.hashCode + i),
            title: name,
            body: "Time to take your $name ${dosage.isNotEmpty ? '($dosage)' : ''}",
            scheduledDate: scheduleTime,
            docId: docRef.id,
            type: 'medication',
            userId: effectiveId,
          );
        }
      }
      clearSpecificDates();
      return null;
    } catch (e) {
      return "Save Error: $e";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> updateMedication({
    required String docId,
    required String? patientId,
    required String name,
    required String dosage,
    required String stock,
    required String dateText,
    required DateTime? selectedDate,
    required String freqType,
    required String freqTimes,
    required List<String> timeStrings,
    required List<TimeOfDay?> timesToSchedule,
  }) async {
    final effectiveId = getEffectivePatientId(patientId);

    for (var t in timesToSchedule) {
      if (t == null) return "Please select all times";
    }

    String newFreq = freqType;
    if (freqType == 'Everyday' || freqType == 'Specific Dates') {
      newFreq = "$freqType ($freqTimes)";
    }

    try {
      await _firestore.collection('reminders').doc(docId).update({
        'title': name,
        'dosage': dosage,
        'date': dateText,
        'times': timeStrings,
        'stock': stock,
        'frequency': newFreq,
      });

      if (selectedDate != null) {
        for (int i = 0; i < timesToSchedule.length; i++) {
          DateTime scheduleTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, timesToSchedule[i]!.hour, timesToSchedule[i]!.minute);
          await NotificationService.scheduleNotification(
            id: (docId.hashCode + i),
            title: name,
            body: "Time to take your $name",
            scheduledDate: scheduleTime,
            docId: docId,
            type: 'medication',
            userId: effectiveId,
          );
        }
      }
      return null;
    } catch (e) {
      return "Update Error: $e";
    }
  }
}