import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/caregiver_request_item.dart';

class CaregiverRequestsViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentCaregiverEmail => _auth.currentUser?.email ?? '';

  Stream<List<CaregiverRequestItem>> getRequestsStream() {
    if (currentCaregiverEmail.isEmpty) return const Stream.empty();

    return _firestore
        .collection('caregiver_requests')
        .where('caregiverEmail', isEqualTo: currentCaregiverEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CaregiverRequestItem.fromFirestore(doc))
        .toList());
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _firestore
          .collection('caregiver_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Accept Request Error: $e");
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _firestore
          .collection('caregiver_requests')
          .doc(requestId)
          .update({
        'status': 'rejected',
      });
    } catch (e) {
      debugPrint("Reject Request Error: $e");
    }
  }
}