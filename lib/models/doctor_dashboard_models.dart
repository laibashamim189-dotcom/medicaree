import 'package:cloud_firestore/cloud_firestore.dart';

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