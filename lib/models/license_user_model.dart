import 'package:cloud_firestore/cloud_firestore.dart';

class LicenseUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String licenseStatus;
  final String? certificateUrl;
  final String? speciality;
  final String? pharmacyName;
  final String? licenseNumber;
  final String? drugLicenseNumber;
  final String? pharmacistRegNumber;
  final String? pharmacyAddress;
  final String? nursingLicenseNumber;
  final DateTime? createdAt;
  final DateTime? verifiedAt;

  LicenseUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.licenseStatus,
    this.certificateUrl,
    this.speciality,
    this.pharmacyName,
    this.licenseNumber,
    this.drugLicenseNumber,
    this.pharmacistRegNumber,
    this.pharmacyAddress,
    this.nursingLicenseNumber,
    this.createdAt,
    this.verifiedAt,
  });

  factory LicenseUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LicenseUserModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? 'N/A',
      role: data['role'] ?? 'Professional',
      licenseStatus: data['licenseStatus'] ?? 'PENDING',
      certificateUrl: data['certificateUrl'],
      speciality: data['speciality'],
      pharmacyName: data['pharmacyName'],
      licenseNumber: data['licenseNumber'],
      drugLicenseNumber: data['drugLicenseNumber'],
      pharmacistRegNumber: data['pharmacistRegNumber'],
      pharmacyAddress: data['pharmacyAddress'],
      nursingLicenseNumber: data['nursingLicenseNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }
}