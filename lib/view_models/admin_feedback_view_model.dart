import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Adminfeedback_model.dart';

class AdminFeedbackViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _selectedIds = {};

  Set<String> get selectedIds => _selectedIds;
  bool get hasSelection => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;

  // Realtime feedback stream using the Admin-specific model
  Stream<List<FeedbackModel>> get feedbackStream {
    return _firestore
        .collection('feedback')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  // Toggle Selection for batch actions
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void addSelection(String id) {
    _selectedIds.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  // Delete selected feedback documents from Firestore
  Future<bool> deleteSelected() async {
    try {
      final batch = _firestore.batch();
      for (var id in _selectedIds) {
        batch.delete(_firestore.collection('feedback').doc(id));
      }
      await batch.commit();
      _selectedIds.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting feedback: $e");
      return false;
    }
  }
}
