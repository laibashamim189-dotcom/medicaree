import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String caregiverEmail;
  final String relationship;
  final String status;
  final Timestamp? timestamp;
  final Timestamp? acceptedAt;

  CaregiverRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.caregiverEmail,
    required this.relationship,
    required this.status,
    this.timestamp,
    this.acceptedAt,
  });

  factory CaregiverRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CaregiverRequestModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown',
      caregiverEmail: data['caregiverEmail'] ?? '',
      relationship: data['relationship'] ?? 'N/A',
      status: data['status'] ?? 'pending',
      timestamp: data['timestamp'] as Timestamp?,
      acceptedAt: data['acceptedAt'] as Timestamp?,
    );
  }
}
