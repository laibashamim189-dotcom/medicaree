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
  final DateTime createdAt;

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
    required this.createdAt,
  });

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

    return map;
  }
}