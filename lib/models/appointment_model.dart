import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;

  AppointmentModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppointmentModel(
      id: doc.id,
      doctorName: data['doctorName'] ?? 'Doctor',
      specialty: data['specialty'] ?? 'Medical Consultation',
      date: data['date'] ?? 'No Date',
      time: data['time'] ?? 'No Time',
    );
  }
}