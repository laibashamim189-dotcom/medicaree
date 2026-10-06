import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyOrderModel {
  final String id;
  final String? medicineName;
  final String? userEmail;
  final String? patientPhone;
  final int quantity;
  final String deliveryStatus;
  final String? deliveryAddress;
  final double? medicinePrice;
  final double? deliveryFee;
  final double? totalAmount;
  final bool deletedByPharmacy;
  final Timestamp? timestamp;

  PharmacyOrderModel({
    required this.id,
    this.medicineName,
    this.userEmail,
    this.patientPhone,
    required this.quantity,
    required this.deliveryStatus,
    this.deliveryAddress,
    this.medicinePrice,
    this.deliveryFee,
    this.totalAmount,
    this.deletedByPharmacy = false,
    this.timestamp,
  });

  factory PharmacyOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PharmacyOrderModel(
      id: doc.id,
      medicineName: data['medicineName'],
      userEmail: data['userEmail'],
      patientPhone: data['patientPhone'],
      quantity: data['quantity'] ?? 1,
      deliveryStatus: data['deliveryStatus'] ?? 'Pending',
      deliveryAddress: data['deliveryAddress'],
      medicinePrice: (data['medicinePrice'] as num?)?.toDouble(),
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      deletedByPharmacy: data['deletedByPharmacy'] ?? false,
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  bool isIncomingStatus() {
    return deliveryStatus == 'Pending (Awaiting Confirmation)';
  }

  bool isAcceptedStatus() {
    return [
      'In Stock (Provide Address)',
      'Delivery Requested',
      'Confirmed (Out for Delivery)',
      'Rejected (Out of Stock)'
    ].contains(deliveryStatus);
  }
}