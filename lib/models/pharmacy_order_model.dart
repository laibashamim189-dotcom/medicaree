import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyOrderModel {
  final String id;
  final String userId;
  final String? userEmail;
  final String? patientPhone;
  final String? medicineName;
  final int quantity;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String? pharmacyManagerEmail;
  final String deliveryStatus;
  final Timestamp? timestamp;
  final double? medicinePrice;
  final double? deliveryFee;
  final double? totalAmount;
  final String? deliveryAddress;
  final bool deletedByPharmacy;

  PharmacyOrderModel({
    required this.id,
    required this.userId,
    this.userEmail,
    this.patientPhone,
    this.medicineName,
    required this.quantity,
    this.pharmacyName,
    this.pharmacyAddress,
    this.pharmacyManagerEmail,
    required this.deliveryStatus,
    this.timestamp,
    this.medicinePrice,
    this.deliveryFee,
    this.totalAmount,
    this.deliveryAddress,
    this.deletedByPharmacy = false,
  });

  factory PharmacyOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PharmacyOrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'],
      patientPhone: data['patientPhone'],
      medicineName: data['medicineName'],
      quantity: data['quantity'] ?? 1,
      pharmacyName: data['pharmacyName'],
      pharmacyAddress: data['pharmacyAddress'],
      pharmacyManagerEmail: data['pharmacyManagerEmail'],
      deliveryStatus: data['deliveryStatus'] ?? 'Pending',
      timestamp: data['timestamp'] as Timestamp?,
      medicinePrice: (data['medicinePrice'] as num?)?.toDouble(),
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      deliveryAddress: data['deliveryAddress'],
      deletedByPharmacy: data['deletedByPharmacy'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'patientPhone': patientPhone,
      'medicineName': medicineName,
      'quantity': quantity,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'pharmacyManagerEmail': pharmacyManagerEmail,
      'deliveryStatus': deliveryStatus,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'medicinePrice': medicinePrice,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'deletedByPharmacy': deletedByPharmacy,
    };
  }

  bool isIncomingStatus() => deliveryStatus == 'Pending (Awaiting Confirmation)';

  bool isAcceptedStatus() {
    return [
      'In Stock (Provide Address)',
      'Delivery Requested',
      'Confirmed (Out for Delivery)',
      'Rejected (Out of Stock)'
    ].contains(deliveryStatus);
  }
}
