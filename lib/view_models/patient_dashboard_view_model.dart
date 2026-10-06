import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';
import '../views/direct_chat_screen.dart';
import '../models/patient_dashboard_model.dart';

class PatientDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int selectedIndex = 0;
  bool isUploadingImage = false;
  StreamSubscription? _notificationSubscription;

  User? get currentUser => _auth.currentUser;

  String getEffectivePatientId(String? patientId) {
    return patientId ?? currentUser?.uid ?? "";
  }

  bool isOwnDashboard(String patientId) {
    return patientId == (currentUser?.uid ?? "");
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Stream<PatientUserProfile> getUserProfileStream(String patientId) {
    return _firestore
        .collection('users')
        .doc(patientId)
        .snapshots()
        .map((snapshot) => PatientUserProfile.fromFirestore(patientId, snapshot.data()));
  }

  void listenForNotifications() {
    final user = currentUser;
    if (user == null) return;
    final String myUid = user.uid.trim().toLowerCase();

    _notificationSubscription?.cancel();
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('toId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final item = DashboardNotificationItem.fromFirestore(change.doc.id, data);

          final String? activeChatId = DirectChatScreen.activeChatId?.toLowerCase();
          if (item.fromId == myUid || (item.chatId != null && item.chatId == activeChatId)) {
            debugPrint("Patient Dashboard: Suppressing notification (Self-sent or Active chat)");
            change.doc.reference.update({'status': 'delivered'});
            continue;
          }

          NotificationService.showImmediateNotification(
            id: change.doc.id.hashCode,
            title: item.title,
            body: item.body,
            channelId: item.type == 'chat' ? 'chat_messages' : 'medication_urgent_v9',
          );
          change.doc.reference.update({'status': 'delivered'});
        }
      }
    }, onError: (e) => debugPrint("Patient Dashboard Notification Listener Error: $e"));

    NotificationService.updateFCMToken();
  }

  Future<String?> pickAndUploadProfileImage(String patientId, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile == null) return null;

    isUploadingImage = true;
    notifyListeners();

    try {
      String? imageUrl = await CloudinaryService.uploadImage(File(pickedFile.path));
      if (imageUrl != null) {
        await _firestore.collection('users').doc(patientId).update({'profileImageUrl': imageUrl});
        return "Profile photo updated successfully!";
      }
      return "Failed to process image upload";
    } catch (e) {
      return "Failed to upload image: $e";
    } finally {
      isUploadingImage = false;
      notifyListeners();
    }
  }

  Future<String?> removeProfilePhoto(String patientId) async {
    isUploadingImage = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(patientId)
          .update({'profileImageUrl': FieldValue.delete()});
      return "Profile photo removed";
    } catch (e) {
      return "Error: $e";
    } finally {
      isUploadingImage = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
