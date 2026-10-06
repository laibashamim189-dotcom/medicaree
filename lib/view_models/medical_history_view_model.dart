import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medical_history_model.dart';

class MedicalHistoryViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isSearching = false;
  String searchQuery = "";

  String? getEffectivePatientId(String? patientId) {
    return patientId ?? _auth.currentUser?.uid;
  }

  void toggleSearch() {
    isSearching = !isSearching;
    if (!isSearching) {
      searchQuery = "";
    }
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
    isSearching = false;
    searchQuery = "";
    notifyListeners();
  }

  Stream<List<MedicalHistoryModel>> getHistoryStream(String? patientId) {
    final effectiveId = getEffectivePatientId(patientId);
    if (effectiveId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('user_history')
        .where('userId', isEqualTo: effectiveId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) => MedicalHistoryModel.fromMap(doc.id, doc.data())).toList();

      if (searchQuery.isEmpty) {
        return docs;
      }

      return docs.where((item) {
        final titleMatch = item.title.toLowerCase().contains(searchQuery);
        final dateMatch = item.date.toLowerCase().contains(searchQuery);
        final timeMatch = item.time.toLowerCase().contains(searchQuery);
        return titleMatch || dateMatch || timeMatch;
      }).toList();
    });
  }

  Future<void> deleteHistoryRecord(String docId) async {
    await _firestore.collection('user_history').doc(docId).delete();
  }
}