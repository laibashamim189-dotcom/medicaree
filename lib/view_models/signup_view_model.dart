import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class SignupViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final licenseController = TextEditingController();
  final specialityController = TextEditingController();
  final pharmacyNameController = TextEditingController();
  final pharmacyAddressController = TextEditingController();
  final drugLicenseController = TextEditingController();
  final pharmacistRegController = TextEditingController();
  final nursingLicenseController = TextEditingController();

  // Observable States
  String? selectedGender;
  String? selectedRole;
  String? selectedCaregiverType;
  bool isLoading = false;
  bool obscurePassword = true;

  final List<String> roles = ['Patient', 'Caregiver', 'Doctor', 'Pharmacist'];
  final List<String> caregiverTypes = ['Nurse', 'Friend', 'Relative'];
  final List<String> genders = ['Male', 'Female', 'Other'];

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void setSelectedRole(String? role) {
    selectedRole = role;
    selectedCaregiverType = null;
    notifyListeners();
  }

  void setSelectedCaregiverType(String? type) {
    selectedCaregiverType = type;
    notifyListeners();
  }

  void setSelectedGender(String? gender) {
    selectedGender = gender;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<String?> signUp() async {
    _setLoading(true);
    try {
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          userCredential = await _auth.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
        } else {
          rethrow;
        }
      }

      final bool isNurse = selectedRole == 'Caregiver' && selectedCaregiverType == 'Nurse';
      final String licenseStatus = (selectedRole == 'Doctor' || selectedRole == 'Pharmacist' || isNurse)
          ? 'NOT_SUBMITTED'
          : 'APPROVED';

      final userModel = UserModel(
        uid: userCredential.user!.uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        role: selectedRole!,
        gender: selectedGender!,
        dob: dobController.text.trim(),
        licenseStatus: licenseStatus,
        caregiverType: selectedCaregiverType,
        nursingLicenseNumber: nursingLicenseController.text.trim(),
        licenseNumber: licenseController.text.trim(),
        speciality: specialityController.text.trim(),
        pharmacyName: pharmacyNameController.text.trim(),
        pharmacyAddress: pharmacyAddressController.text.trim(),
        drugLicenseNumber: drugLicenseController.text.trim(),
        pharmacistRegNumber: pharmacistRegController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userModel.toMap());
      await NotificationService.updateFCMToken();

      return null; // Success (No Error Message)
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Registration Failed";
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    dobController.dispose();
    licenseController.dispose();
    specialityController.dispose();
    pharmacyNameController.dispose();
    pharmacyAddressController.dispose();
    drugLicenseController.dispose();
    pharmacistRegController.dispose();
    nursingLicenseController.dispose();
    super.dispose();
  }
}