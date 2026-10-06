import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineOrderModel {
  final String id;
  final String userId;
  final String userEmail;
  final String patientPhone;
  final String medicineName;
  final int quantity;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyManagerEmail;
  final String deliveryStatus;
  final DateTime? timestamp;
  final double? medicinePrice;
  final double? deliveryFee;
  final double? totalAmount;
  final String? deliveryAddress;

  MedicineOrderModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.patientPhone,
    required this.medicineName,
    required this.quantity,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyManagerEmail,
    required this.deliveryStatus,
    this.timestamp,
    this.medicinePrice,
    this.deliveryFee,
    this.totalAmount,
    this.deliveryAddress,
  });

  factory MedicineOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicineOrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      patientPhone: data['patientPhone'] ?? '',
      medicineName: data['medicineName'] ?? '',
      quantity: data['quantity'] ?? 1,
      pharmacyName: data['pharmacyName'] ?? '',
      pharmacyAddress: data['pharmacyAddress'] ?? '',
      pharmacyManagerEmail: data['pharmacyManagerEmail'] ?? '',
      deliveryStatus: data['deliveryStatus'] ?? 'Pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      medicinePrice: (data['medicinePrice'] as num?)?.toDouble(),
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      deliveryAddress: data['deliveryAddress'],
    );
  }
}