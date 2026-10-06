import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';
import '../models/pharmacist_license_model.dart';

class PharmacistLicenseViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController drugLicenseController = TextEditingController();
  final TextEditingController pharmacistRegController = TextEditingController();
  final TextEditingController pharmacyNameController = TextEditingController();
  final TextEditingController pharmacyAddressController = TextEditingController();

  File? certificateFile;
  bool isSubmitting = false;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  User? get currentUser => _auth.currentUser;

  void initialize() {
    listenForAdminAlerts();
    NotificationService.updateFCMToken();
  }

  void listenForAdminAlerts() {
    final user = currentUser;
    if (user == null) return;

    _notificationSubscription?.cancel();
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('toId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          NotificationService.showImmediateNotification(
            id: change.doc.id.hashCode,
            title: data['title'] ?? "License Update",
            body: data['body'] ?? "",
            channelId: 'medication_urgent_v9',
          );
          change.doc.reference.update({'status': 'delivered'});
        }
      }
    });
  }

  Stream<PharmacistLicenseModel?> getLicenseStatusStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final model = PharmacistLicenseModel.fromFirestore(snapshot);
      _populateControllers(model);
      return model;
    });
  }

  void _populateControllers(PharmacistLicenseModel model) {
    if (drugLicenseController.text.isEmpty && model.drugLicenseNumber != null) {
      drugLicenseController.text = model.drugLicenseNumber!;
    }
    if (pharmacistRegController.text.isEmpty && model.pharmacistRegNumber != null) {
      pharmacistRegController.text = model.pharmacistRegNumber!;
    }
    if (pharmacyNameController.text.isEmpty && model.pharmacyName != null) {
      pharmacyNameController.text = model.pharmacyName!;
    }
    if (pharmacyAddressController.text.isEmpty && model.pharmacyAddress != null) {
      pharmacyAddressController.text = model.pharmacyAddress!;
    }
  }

  Future<String?> pickCertificate() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        certificateFile = File(pickedFile.path);
        notifyListeners();
        return null;
      }
      return null;
    } catch (e) {
      return "Error picking image: $e";
    }
  }

  Future<String?> submitLicense(String? existingUrl) async {
    final user = currentUser;
    if (user == null) return "User session expired";

    if (certificateFile == null && (existingUrl == null || existingUrl.isEmpty)) {
      return "Please upload your Drug License Certificate image";
    }

    isSubmitting = true;
    notifyListeners();

    try {
      String? imageUrl = existingUrl;
      if (certificateFile != null) {
        imageUrl = await CloudinaryService.uploadImage(certificateFile!);
      }

      final submissionData = PharmacistLicenseModel(
        uid: user.uid,
        licenseStatus: 'PENDING',
        drugLicenseNumber: drugLicenseController.text.trim(),
        pharmacistRegNumber: pharmacistRegController.text.trim(),
        pharmacyName: pharmacyNameController.text.trim(),
        pharmacyAddress: pharmacyAddressController.text.trim(),
        certificateUrl: imageUrl,
      ).toSubmissionMap(imageUrl);

      await _firestore.collection('users').doc(user.uid).update(submissionData);
      return null; // Return null on success
    } catch (e) {
      return "Error: $e";
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    drugLicenseController.dispose();
    pharmacistRegController.dispose();
    pharmacyNameController.dispose();
    pharmacyAddressController.dispose();
    super.dispose();
  }
}