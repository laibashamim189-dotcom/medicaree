import 'package:flutter/material.dart';

class MedicalHistoryModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String status;
  final String date;
  final String time;

  MedicalHistoryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.status,
    required this.date,
    required this.time,
  });

  bool get isSuccess {
    return status.startsWith('Taken') ||
        status.startsWith('Measured') ||
        status.startsWith('Completed') ||
        status.startsWith('Attended') ||
        status.startsWith('Done');
  }

  Color get statusColor => isSuccess ? Colors.green : Colors.red;

  factory MedicalHistoryModel.fromMap(String docId, Map<String, dynamic> data) {
    return MedicalHistoryModel(
      id: docId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Record',
      category: (data['category'] ?? 'General').toString().toUpperCase(),
      status: data['status'] ?? 'Marked',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'status': status,
      'date': date,
      'time': time,
    };
  }
}