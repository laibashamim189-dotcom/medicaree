import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorVerificationModel {
  final String uid;
  final String licenseNumber;
  final String speciality;
  final String? certificateUrl;
  final String licenseStatus;

  DoctorVerificationModel({
    required this.uid,
    required this.licenseNumber,
    required this.speciality,
    this.certificateUrl,
    required this.licenseStatus,
  });

  factory DoctorVerificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DoctorVerificationModel(
      uid: doc.id,
      licenseNumber: data['licenseNumber'] ?? '',
      speciality: data['speciality'] ?? '',
      certificateUrl: data['certificateUrl'],
      licenseStatus: (data['licenseStatus'] ?? 'NOT_SUBMITTED').toString().toUpperCase().trim(),
    );
  }

  bool get isEditable => licenseStatus == 'NOT_SUBMITTED' || licenseStatus == 'REJECTED';
}