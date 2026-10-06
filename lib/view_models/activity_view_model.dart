import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/activity_model.dart';
import '../services/notification_service.dart';

class ActivityViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // Stream for activity reminders
  Stream<QuerySnapshot> getActivityReminders(String patientId) {
    final effectiveId = patientId.isNotEmpty
        ? patientId
        : FirebaseAuth.instance.currentUser?.uid ?? "";

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: effectiveId)
        .where('type', isEqualTo: 'activity')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete activity
  Future<void> deleteActivity(String docId) async {
    await _firestore.collection('reminders').doc(docId).delete();
  }

  // Save new activity
  Future<bool> saveActivity({
    required String patientId,
    required String activityType,
    required String duration,
    required String frequencyType,
    required String frequencyTimes,
    required DateTime? selectedDate,
    required List<DateTime> selectedDates,
    required List<TimeOfDay?> timesToSchedule,
    required List<String> timeStrings,
  }) async {
    final effectiveId = patientId.isNotEmpty
        ? patientId
        : FirebaseAuth.instance.currentUser?.uid ?? "";

    if (effectiveId.isEmpty) return false;

    List<DateTime> datesToProcess = [];
    if (frequencyType != 'Specific Dates') {
      if (selectedDate == null) return false;
      datesToProcess.add(selectedDate);
    } else {
      if (selectedDates.isEmpty) return false;
      datesToProcess.addAll(selectedDates);
    }

    _isSaving = true;
    notifyListeners();

    try {
      for (DateTime date in datesToProcess) {
        final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

        String displayFreq = frequencyType;
        if (frequencyType == 'Everyday' || frequencyType == 'Specific Dates') {
          displayFreq = "$frequencyType ($frequencyTimes)";
        }

        final activity = ActivityModel(
          userId: effectiveId,
          title: activityType,
          duration: duration,
          date: formattedDate,
          times: timeStrings,
          frequency: displayFreq,
        );

        final docRef = await _firestore.collection('reminders').add(activity.toFirestore());

        for (int i = 0; i < timesToSchedule.length; i++) {
          TimeOfDay currentT = timesToSchedule[i]!;
          DateTime scheduleTime = DateTime(date.year, date.month, date.day, currentT.hour, currentT.minute);

          await NotificationService.scheduleNotification(
            id: (docRef.id.hashCode + i),
            title: activityType,
            body: "Time for $activityType",
            scheduledDate: scheduleTime,
            docId: docRef.id,
            type: 'activity',
            userId: effectiveId,
          );
        }
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Save Error: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Update activity
  Future<bool> updateActivity({
    required DocumentSnapshot doc,
    required String patientId,
    required String activityType,
    required String duration,
    required String dateText,
    required String newFrequency,
    required List<String> timeStrings,
    required List<TimeOfDay?> timesToSchedule,
    required DateTime? selectedDate,
  }) async {
    final effectiveId = patientId.isNotEmpty
        ? patientId
        : FirebaseAuth.instance.currentUser?.uid ?? "";

    try {
      await doc.reference.update({
        'title': activityType,
        'duration': duration,
        'date': dateText,
        'times': timeStrings,
        'frequency': newFrequency,
      });

      if (selectedDate != null) {
        for (int i = 0; i < timesToSchedule.length; i++) {
          DateTime scheduleTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              timesToSchedule[i]!.hour,
              timesToSchedule[i]!.minute
          );

          await NotificationService.scheduleNotification(
            id: (doc.id.hashCode + i),
            title: activityType,
            body: "Time for $activityType",
            scheduledDate: scheduleTime,
            docId: doc.id,
            type: 'activity',
            userId: effectiveId,
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint("Update error: $e");
      return false;
    }
  }
}