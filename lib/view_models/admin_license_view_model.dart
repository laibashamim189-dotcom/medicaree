import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/license_user_model.dart';

class AdminLicenseViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedRole = 'Doctor';
  String get selectedRole => _selectedRole;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String _searchText = '';
  String get searchText => _searchText;

  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;
  bool get hasSelection => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;

  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void toggleSearch() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      _searchText = '';
    }
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

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

  // Real-time listener for new incoming requests
  Stream<QuerySnapshot> getIncomingRequestsStream() {
    return _firestore
        .collection('users')
        .where('licenseStatus', isEqualTo: 'PENDING')
        .snapshots();
  }

  // Real-time query according to selected role and status
  Stream<List<LicenseUserModel>> getLicenseUsersStream(String status) {
    Query query = _firestore.collection('users');

    if (_selectedRole == 'Nurse') {
      query = query
          .where('role', isEqualTo: 'Caregiver')
          .where('caregiverType', isEqualTo: 'Nurse');
    } else {
      query = query.where('role', isEqualTo: _selectedRole);
    }

    return query
        .where('licenseStatus', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LicenseUserModel.fromFirestore(doc))
        .toList());
  }

  // Update License Status & Send Notification
  Future<bool> updateLicenseStatus({
    required String docId,
    required String newStatus,
    required String name,
  }) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'licenseStatus': newStatus,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      String title = newStatus == 'APPROVED' ? "License Verified! ✅" : "License Rejected ❌";
      String body = newStatus == 'APPROVED'
          ? "Congratulations $name! Your professional license has been verified."
          : "Sorry $name, your license verification was rejected. Please contact support.";

      await _firestore.collection('notifications').add({
        'toId': docId,
        'title': title,
        'body': body,
        'type': 'license_update',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Update error: $e");
      return false;
    }
  }

  // Delete selected users batch
  Future<bool> deleteSelectedUsers() async {
    try {
      final batch = _firestore.batch();
      for (var id in _selectedIds) {
        batch.delete(_firestore.collection('users').doc(id));
      }
      await batch.commit();
      _selectedIds.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Delete error: $e");
      return false;
    }
  }
}