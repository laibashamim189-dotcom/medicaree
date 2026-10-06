import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacistLicenseModel {
  final String uid;
  final String licenseStatus;
  final String? drugLicenseNumber;
  final String? pharmacistRegNumber;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String? certificateUrl;

  PharmacistLicenseModel({
    required this.uid,
    required this.licenseStatus,
    this.drugLicenseNumber,
    this.pharmacistRegNumber,
    this.pharmacyName,
    this.pharmacyAddress,
    this.certificateUrl,
  });

  factory PharmacistLicenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PharmacistLicenseModel(
      uid: doc.id,
      licenseStatus: (data['licenseStatus'] ?? 'NOT_SUBMITTED').toString().toUpperCase().trim(),
      drugLicenseNumber: data['drugLicenseNumber'],
      pharmacistRegNumber: data['pharmacistRegNumber'],
      pharmacyName: data['pharmacyName'],
      pharmacyAddress: data['pharmacyAddress'],
      certificateUrl: data['certificateUrl'],
    );
  }

  Map<String, dynamic> toSubmissionMap(String? imageUrl) {
    return {
      'drugLicenseNumber': drugLicenseNumber,
      'pharmacistRegNumber': pharmacistRegNumber,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'certificateUrl': imageUrl,
      'licenseStatus': 'PENDING',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}