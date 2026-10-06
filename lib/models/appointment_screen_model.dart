import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentScreenModel {
  final String id;
  final String userId;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;

  AppointmentScreenModel({
    required this.id,
    required this.userId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
  });

  factory AppointmentScreenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppointmentScreenModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      doctorName: data['doctorName'] ?? 'Doctor',
      specialty: data['specialty'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': "Appt: $doctorName",
      'doctorName': doctorName,
      'specialty': specialty,
      'date': date,
      'time': time,
      'type': 'appointment',
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}