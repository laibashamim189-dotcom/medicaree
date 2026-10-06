import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/pharmacy_order_model.dart';

class PharmacyDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  User? get currentUser => _auth.currentUser;
  String get managerEmail => currentUser?.email?.toLowerCase().trim() ?? "";

  void initialize() {
    listenForNotifications();
    NotificationService.updateFCMToken();
  }

  void listenForNotifications() {
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
            title: data['title'] ?? "New Alert",
            body: data['body'] ?? "",
            channelId: data['type'] == 'chat' ? 'chat_messages' : 'medication_urgent_v9',
          );
          change.doc.reference.update({'status': 'delivered'});
        }
      }
    });
  }

  Stream<List<PharmacyOrderModel>> getOrdersStream({required bool isIncoming}) {
    if (managerEmail.isEmpty) return Stream.value([]);

    return _firestore
        .collection('medicine_orders')
        .where('pharmacyManagerEmail', isEqualTo: managerEmail)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => PharmacyOrderModel.fromFirestore(doc))
          .where((order) {
        if (order.deletedByPharmacy) return false;
        return isIncoming ? order.isIncomingStatus() : order.isAcceptedStatus();
      }).toList();

      docs.sort((a, b) {
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });

      return docs;
    });
  }

  Future<String?> updateOrderStatus(String orderId, String newStatus, {Map<String, dynamic>? additionalData}) async {
    try {
      Map<String, dynamic> updateData = {'deliveryStatus': newStatus};
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore.collection('medicine_orders').doc(orderId).update(updateData);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> confirmStockAndPricing({
    required String orderId,
    required int quantity,
    required String costText,
    required String deliveryFeeText,
  }) async {
    final double cost = double.tryParse(costText.trim()) ?? 0.0;
    final double deliveryFee = double.tryParse(deliveryFeeText.trim()) ?? 0.0;
    final double total = (cost * quantity) + deliveryFee;

    return await updateOrderStatus(
      orderId,
      'In Stock (Provide Address)',
      additionalData: {
        'medicinePrice': cost,
        'deliveryFee': deliveryFee,
        'totalAmount': total,
      },
    );
  }

  Future<String?> performSoftDelete(String orderId) async {
    try {
      await _firestore.collection('medicine_orders').doc(orderId).update({'deletedByPharmacy': true});
      return null;
    } catch (e) {
      return e.toString();
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