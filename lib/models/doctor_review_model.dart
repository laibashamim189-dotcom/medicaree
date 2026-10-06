import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorReviewRecommendation {
  final String meds;
  final String activities;
  final String measurements;
  final String targetSystolic;
  final String targetDiastolic;
  final String managedBy;
  final bool needsPhysicalCaregiver;

  DoctorReviewRecommendation({
    this.meds = '',
    this.activities = '',
    this.measurements = '',
    this.targetSystolic = '',
    this.targetDiastolic = '',
    this.managedBy = 'Patient',
    this.needsPhysicalCaregiver = false,
  });

  factory DoctorReviewRecommendation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return DoctorReviewRecommendation();
    return DoctorReviewRecommendation(
      meds: map['meds'] ?? '',
      activities: map['activities'] ?? '',
      measurements: map['measurements'] ?? '',
      targetSystolic: map['targetSystolic'] ?? '',
      targetDiastolic: map['targetDiastolic'] ?? '',
      managedBy: map['managedBy'] ?? 'Patient',
      needsPhysicalCaregiver: map['needsPhysicalCaregiver'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meds': meds,
      'activities': activities,
      'measurements': measurements,
      'targetSystolic': targetSystolic,
      'targetDiastolic': targetDiastolic,
      'managedBy': managedBy,
      'needsPhysicalCaregiver': needsPhysicalCaregiver,
    };
  }
}

class DoctorReviewData {
  final String appointmentId;
  final String status;
  final DoctorReviewRecommendation recommendations;

  DoctorReviewData({
    required this.appointmentId,
    required this.status,
    required this.recommendations,
  });

  bool get isApproved => status == 'Approved';

  factory DoctorReviewData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DoctorReviewData(
      appointmentId: doc.id,
      status: data['status'] ?? '',
      recommendations: DoctorReviewRecommendation.fromMap(
        data['recommendations'] as Map<String, dynamic>?,
      ),
    );
  }
}