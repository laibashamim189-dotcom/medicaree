import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String detail;
  final String date;
  final String time;
  final String status;
  final String type; // 'doctor_request', 'caregiver_request', 'appointment'
  final String? doctorId;
  final String? caregiverId;
  final Map<String, dynamic>? recommendations;

  MedicalItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.date,
    required this.time,
    required this.status,
    required this.type,
    this.doctorId,
    this.caregiverId,
    this.recommendations,
  });

  factory MedicalItemModel.fromFirestore(DocumentSnapshot doc, String type) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    if (type == 'appointment') {
      return MedicalItemModel(
        id: doc.id,
        title: data['doctorName'] ?? '',
        subtitle: data['specialty'] ?? '',
        detail: '',
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        status: data['status'] ?? 'Pending',
        type: type,
      );
    } else if (type == 'doctor_request') {
      return MedicalItemModel(
        id: doc.id,
        title: data['doctorName'] ?? '',
        subtitle: data['specialty'] ?? '',
        detail: data['symptoms'] ?? '',
        date: '',
        time: '',
        status: data['status'] ?? 'Pending',
        type: type,
        doctorId: data['doctorId'],
        recommendations: data['recommendations'] as Map<String, dynamic>?,
      );
    } else {
      return MedicalItemModel(
        id: doc.id,
        title: data['caregiverName'] ?? '',
        subtitle: data['relationship'] ?? '',
        detail: data['caregiverEmail'] ?? '',
        date: '',
        time: '',
        status: data['status'] ?? 'Pending',
        type: type,
        caregiverId: data['caregiverId'],
      );
    }
  }
}
