import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String gender;
  final String dob;
  final String licenseStatus;
  final String? caregiverType;
  final String? nursingLicenseNumber;
  final String? licenseNumber;
  final String? speciality;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String? drugLicenseNumber;
  final String? pharmacistRegNumber;
  final String? certificateUrl;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.gender,
    required this.dob,
    required this.licenseStatus,
    this.caregiverType,
    this.nursingLicenseNumber,
    this.licenseNumber,
    this.speciality,
    this.pharmacyName,
    this.pharmacyAddress,
    this.drugLicenseNumber,
    this.pharmacistRegNumber,
    this.certificateUrl,
    required this.createdAt,
    this.verifiedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'No Name',
      email: data['email'] ?? 'No Email',
      role: data['role'] ?? 'Patient',
      gender: data['gender'] ?? 'N/A',
      dob: data['dob'] ?? 'N/A',
      licenseStatus: data['licenseStatus'] ?? 'NOT_SUBMITTED',
      caregiverType: data['caregiverType'],
      nursingLicenseNumber: data['nursingLicenseNumber'],
      licenseNumber: data['licenseNumber'],
      speciality: data['speciality'],
      pharmacyName: data['pharmacyName'],
      pharmacyAddress: data['pharmacyAddress'],
      drugLicenseNumber: data['drugLicenseNumber'],
      pharmacistRegNumber: data['pharmacistRegNumber'],
      certificateUrl: data['certificateUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Colors.blue;
      case 'patient':
        return Colors.green;
      case 'caregiver':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'gender': gender,
      'dob': dob,
      'licenseStatus': licenseStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (role == 'Caregiver') {
      map['caregiverType'] = caregiverType;
      if (caregiverType == 'Nurse') {
        map['nursingLicenseNumber'] = nursingLicenseNumber;
      }
    }

    if (role == 'Doctor') {
      map['licenseNumber'] = licenseNumber;
      map['speciality'] = speciality;
    }

    if (role == 'Pharmacist') {
      map['pharmacyName'] = pharmacyName;
      map['pharmacyAddress'] = pharmacyAddress;
      map['drugLicenseNumber'] = drugLicenseNumber;
      map['pharmacistRegNumber'] = pharmacistRegNumber;
    }
    
    if (certificateUrl != null) map['certificateUrl'] = certificateUrl;
    if (verifiedAt != null) map['verifiedAt'] = Timestamp.fromDate(verifiedAt!);

    return map;
  }
}
