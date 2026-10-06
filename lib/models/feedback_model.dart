import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String feedbackText;
  final DateTime? timestamp;

  FeedbackModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.feedbackText,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'feedback': feedbackText,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}