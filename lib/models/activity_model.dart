import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String? id;
  final String userId;
  final String title;
  final String duration;
  final String date;
  final List<String> times;
  final String frequency;
  final String status;
  final DateTime? timestamp;

  ActivityModel({
    this.id,
    required this.userId,
    required this.title,
    required this.duration,
    required this.date,
    required this.times,
    required this.frequency,
    this.status = 'Pending',
    this.timestamp,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> parsedTimes = [];
    if (data['times'] != null) {
      parsedTimes = List<String>.from(data['times']);
    } else if (data['time'] != null) {
      parsedTimes = [data['time']];
    }

    return ActivityModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Activity',
      duration: data['duration'] ?? '',
      date: data['date'] ?? '',
      times: parsedTimes,
      frequency: data['frequency'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'duration': duration,
      'date': date,
      'times': times,
      'type': 'activity',
      'frequency': frequency,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}