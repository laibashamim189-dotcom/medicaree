import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Model for Patient Requests on Dashboard
class DoctorRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String symptoms;
  final String status;
  final bool deletedByDoctor;

  DoctorRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.symptoms,
    required this.status,
    required this.deletedByDoctor,
  });

  factory DoctorRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DoctorRequestModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Patient',
      symptoms: data['symptoms'] ?? 'N/A',
      status: data['status'] ?? 'Pending',
      deletedByDoctor: data['deletedByDoctor'] ?? false,
    );
  }
}

// 2. Model for Payments/Fees
class PaymentModel {
  final String id;
  final String patientName;
  final String transactionId;
  final String status;
  final String screenshotUrl;
  final bool deletedByDoctor;

  PaymentModel({
    required this.id,
    required this.patientName,
    required this.transactionId,
    required this.status,
    required this.screenshotUrl,
    required this.deletedByDoctor,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentModel(
      id: doc.id,
      patientName: data['patientName'] ?? 'Patient',
      transactionId: data['transactionId'] ?? 'N/A',
      status: data['status'] ?? 'Pending',
      screenshotUrl: data['screenshotUrl'] ?? '',
      deletedByDoctor: data['deletedByDoctor'] ?? false,
    );
  }
}

// 3. Model for Doctor's Recommendations (Meds, Activities, etc.)
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

// 4. Model for the complete Review Data
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
