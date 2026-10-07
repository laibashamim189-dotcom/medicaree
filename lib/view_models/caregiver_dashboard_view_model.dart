import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/caregiver_request_model.dart';
import '../services/notification_service.dart';
import '../views/direct_chat_screen.dart';

class CaregiverDashboardViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  StreamSubscription? _notificationSubscription;

  void init() {
    listenForNotifications();
    NotificationService.updateFCMToken();
  }

  void listenForNotifications() {
    if (currentUser == null) return;
    final String myUid = currentUser!.uid.trim().toLowerCase();

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('toId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;

          final String fromId = (data['fromId'] ?? data['senderId'] ?? "").toString().trim().toLowerCase();
          final String? notifyChatId = data['chatId']?.toString().toLowerCase();
          final String? activeChatId = DirectChatScreen.activeChatId?.toLowerCase();

          if (fromId == myUid || (notifyChatId != null && notifyChatId == activeChatId)) {
            change.doc.reference.update({'status': 'delivered'});
            continue;
          }

          NotificationService.showImmediateNotification(
            id: change.doc.id.hashCode,
            title: data['title'] ?? "New Alert",
            body: data['body'] ?? "",
            channelId: data['type'] == 'chat' ? 'chat_messages' : 'medication_urgent_v9',
          );
          change.doc.reference.update({'status': 'delivered'});
        }
      }
    }, onError: (e) => debugPrint("Caregiver Dashboard Notification Listener Error: $e"));
  }

  Stream<List<CaregiverRequestModel>> getCaregiverRequestsStream() {
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('caregiver_requests')
        .where('caregiverEmail', isEqualTo: currentUser!.email)
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs.map((doc) => CaregiverRequestModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });
      return list;
    });
  }

  Future<void> acceptRequest(String docId, String patientName, VoidCallback onSuccess) async {
    if (currentUser == null) return;
    try {
      await _firestore.collection('caregiver_requests').doc(docId).update({
        'status': 'accepted',
        'caregiverId': currentUser!.uid,
      });
      onSuccess();
    } catch (e) {
      debugPrint("Accept Request Error: $e");
    }
  }

  Future<void> declineRequest(String docId) async {
    try {
      await _firestore.collection('caregiver_requests').doc(docId).delete();
    } catch (e) {
      debugPrint("Decline Request Error: $e");
    }
  }
  Future<bool> checkPatientReadOnlyAccess(String patientId) async {
    try {
      // Logic: If the caregiver is accepted for this patient, we give them edit rights
      var cgSnap = await _firestore
          .collection('caregiver_requests')
          .where('patientId', isEqualTo: patientId)
          .where('caregiverId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (cgSnap.docs.isNotEmpty) {
        return false; 
      }

      // Fallback to doctor recommendation logic
      var docReqSnap = await _firestore
          .collection('doctor_requests')
          .where('patientId', isEqualTo: patientId)
          .get();

      if (docReqSnap.docs.isNotEmpty) {
        var approvedDocs = docReqSnap.docs.where((doc) => doc['status'] == 'Approved').toList();
        if (approvedDocs.isNotEmpty) {
          approvedDocs.sort((a, b) {
            var t1 = a['timestamp'] as Timestamp?;
            var t2 = b['timestamp'] as Timestamp?;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });

          var latestDoc = approvedDocs.first.data();
          var recs = latestDoc['recommendations'] as Map<String, dynamic>?;
          if (recs != null) {
            String managedBy = (recs['managedBy'] ?? '').toString().toLowerCase();
            if (managedBy == 'both' || managedBy == 'caregiver') return false;
          }
        }
      }
    } catch (e) {
      debugPrint("Check Read-Only Access Error: $e");
    }
    return true;
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({'isRead': true});
    } catch (e) {
      debugPrint("Mark Chat Read Error: $e");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}