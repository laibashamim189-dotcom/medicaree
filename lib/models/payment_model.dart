import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String? doctorId;
  final String doctorName;
  final String transactionId;
  final String paymentNumber;
  final String paymentMethod;
  final String screenshotUrl;
  final String status;
  final DateTime? timestamp;

  PaymentRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.doctorId,
    required this.doctorName,
    required this.transactionId,
    required this.paymentNumber,
    required this.paymentMethod,
    required this.screenshotUrl,
    required this.status,
    this.timestamp,
  });

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentRecord(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Patient',
      doctorId: data['doctorId'],
      doctorName: data['doctorName'] ?? 'Doctor',
      transactionId: data['transactionId'] ?? '',
      paymentNumber: data['paymentNumber'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'EasyPaisa',
      screenshotUrl: data['screenshotUrl'] ?? '',
      status: data['status'] ?? 'Pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'transactionId': transactionId,
      'paymentNumber': paymentNumber,
      'paymentMethod': paymentMethod,
      'screenshotUrl': screenshotUrl,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}