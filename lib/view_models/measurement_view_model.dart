import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/measurement_model.dart';
import '../services/notification_service.dart';

class MeasurementViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isSaving = false;

  String getEffectivePatientId(String? patientId) {
    return patientId ?? _auth.currentUser?.uid ?? "";
  }

  Stream<List<MeasurementModel>> getMeasurementRemindersStream(String patientId) {
    final effectiveId = getEffectivePatientId(patientId);
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: effectiveId)
        .where('type', isEqualTo: 'measurement')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MeasurementModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  TimeOfDay parseTime(String timeStr) {
    try {
      return TimeOfDay.fromDateTime(DateFormat.jm().parse(timeStr));
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  Future<void> deleteMeasurement(String docId) async {
    await _firestore.collection('reminders').doc(docId).delete();
  }

  Future<void> addMeasurement({
    required String patientId,
    required String category,
    required String frequencyType,
    required String frequencyTimes,
    required DateTime startDate,
    required List<DateTime> selectedDatesList,
    required TimeOfDay time1,
    required TimeOfDay? time2,
    required TimeOfDay? time3,
    required BuildContext context,
  }) async {
    isSaving = true;
    notifyListeners();

    try {
      final effectiveId = getEffectivePatientId(patientId);

      List<DateTime> datesToProcess = [];
      if (frequencyType != 'Specific Dates') {
        datesToProcess.add(startDate);
      } else {
        if (selectedDatesList.isEmpty) {
          isSaving = false;
          notifyListeners();
          return;
        }
        datesToProcess.addAll(selectedDatesList);
      }

      List<TimeOfDay> times = [time1];
      List<String> timeStrings = [time1.format(context)];

      if (frequencyTimes == 'Twice a day' && time2 != null) {
        times.add(time2);
        timeStrings.add(time2.format(context));
      } else if (frequencyTimes == '3 times a day') {
        if (time2 != null) {
          times.add(time2);
          timeStrings.add(time2.format(context));
        }
        if (time3 != null) {
          times.add(time3);
          timeStrings.add(time3.format(context));
        }
      }

      String displayFreq = frequencyType;
      if (frequencyType == 'Everyday' || frequencyType == 'Specific Dates') {
        displayFreq = "$frequencyType ($frequencyTimes)";
      }

      for (DateTime date in datesToProcess) {
        final String setDateStr = DateFormat('yyyy-MM-dd').format(date);
        final docRef = await _firestore.collection('reminders').add({
          'userId': effectiveId,
          'title': category,
          'type': 'measurement',
          'date': setDateStr,
          'times': timeStrings,
          'frequency': displayFreq,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        for (int i = 0; i < times.length; i++) {
          await NotificationService.scheduleNotification(
            id: (docRef.id.hashCode + i),
            title: category,
            body: "Time to check your $category",
            scheduledDate: DateTime(date.year, date.month, date.day, times[i].hour, times[i].minute),
            docId: docRef.id,
            type: 'measurement',
            userId: effectiveId,
          );
        }
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateMeasurement({
    required String docId,
    required String patientId,
    required String category,
    required String frequencyType,
    required String frequencyTimes,
    required String dateStr,
    required List<String> timeStrings,
    required DateTime tempDate,
    required BuildContext context,
  }) async {
    final effectiveId = getEffectivePatientId(patientId);

    String displayFreq = frequencyType;
    if (frequencyType == 'Everyday' || frequencyType == 'Specific Dates') {
      displayFreq = "$frequencyType ($frequencyTimes)";
    }

    await _firestore.collection('reminders').doc(docId).update({
      'title': category,
      'date': dateStr,
      'times': timeStrings,
      'frequency': displayFreq,
    });

    for (int i = 0; i < timeStrings.length; i++) {
      TimeOfDay t = parseTime(timeStrings[i]);
      DateTime scheduleTime = DateTime(tempDate.year, tempDate.month, tempDate.day, t.hour, t.minute);
      await NotificationService.scheduleNotification(
        id: (docId.hashCode + i),
        title: category,
        body: "Time to check your $category",
        scheduledDate: scheduleTime,
        docId: docId,
        type: 'measurement',
        userId: effectiveId,
      );
    }
  }
}