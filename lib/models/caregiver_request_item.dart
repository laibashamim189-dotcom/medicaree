import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverRequestItem {
  final String id;
  final String patientName;
  final String caregiverEmail;
  final String relationship;
  final String status;
  final Timestamp? acceptedAt;

  CaregiverRequestItem({
    required this.id,
    required this.patientName,
    required this.caregiverEmail,
    required this.relationship,
    required this.status,
    this.acceptedAt,
  });

  factory CaregiverRequestItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CaregiverRequestItem(
      id: doc.id,
      patientName: data['patientName'] ?? 'Unknown',
      caregiverEmail: data['caregiverEmail'] ?? '',
      relationship: data['relationship'] ?? 'N/A',
      status: data['status'] ?? 'pending',
      acceptedAt: data['acceptedAt'] as Timestamp?,
    );
  }
}