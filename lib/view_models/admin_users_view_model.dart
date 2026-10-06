import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_model.dart';

class AdminUsersViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  void toggleSearch() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      _searchQuery = '';
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // Firestore stream for all registered users
  Stream<List<AppUserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUserModel.fromFirestore(doc)).toList();
    });
  }

  // Filter users list based on search query
  List<AppUserModel> filterUsers(List<AppUserModel> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final String name = user.name.toLowerCase();
      final String role = user.role.toLowerCase();
      final String email = user.email.toLowerCase();

      return name.contains(_searchQuery) ||
          role.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();
  }
}