import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_dashboard_models.dart';
import '../services/notification_service.dart';
import '../views/direct_chat_screen.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _notificationSubscription;

  User? get currentUser => _auth.currentUser;
  String get currentDoctorId => currentUser?.uid ?? '';
  String get currentDoctorEmail => currentUser?.email ?? '';

  void initNotificationListener() {
    if (currentDoctorId.isEmpty) return;

    NotificationService.updateFCMToken();

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('toId', isEqualTo: currentDoctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;

          final String myUid = currentDoctorId.trim().toLowerCase();
          final String fromId = (data['fromId'] ?? data['senderId'] ?? "").toString().trim().toLowerCase();
          final String? notifyChatId = data['chatId']?.toString().toLowerCase();
          final String? activeChatId = DirectChatScreen.activeChatId?.toLowerCase();

          if (fromId == myUid || (notifyChatId != null && notifyChatId == activeChatId)) {
            debugPrint("Doctor Dashboard: Suppressing notification");
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
    }, onError: (e) => debugPrint("Doctor Dashboard Notification Listener Error: $e"));
  }

  Stream<List<DoctorRequestModel>> getRequestsStream(String status) {
    Query query = _firestore.collection('doctor_requests').where('status', isEqualTo: status);
    if (status == 'Pending') {
      query = query.where('doctorEmail', isEqualTo: currentDoctorEmail);
    } else {
      query = query.where('doctorId', isEqualTo: currentDoctorId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorRequestModel.fromFirestore(doc))
          .where((req) => !req.deletedByDoctor)
          .toList();
    });
  }

  Stream<List<PaymentModel>> getPaymentsStream() {
    return _firestore
        .collection('payments')
        .where('doctorId', isEqualTo: currentDoctorId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .where((payment) => !payment.deletedByDoctor)
          .toList();
    });
  }

  Stream<bool> getUnreadChatStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        return data['lastSenderId'] != currentDoctorId && data['isRead'] == false;
      }
      return false;
    });
  }

  Future<void> markChatAsRead(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({'isRead': true}).catchError((e) => null);
  }

  Future<void> performSoftDelete(String requestId) async {
    await _firestore.collection('doctor_requests').doc(requestId).update({'deletedByDoctor': true});
  }

  Future<void> performPaymentSoftDelete(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).update({'deletedByDoctor': true});
  }

  Future<void> updatePaymentStatus(String docId, String newStatus) async {
    await _firestore.collection('payments').doc(docId).update({'status': newStatus});
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
