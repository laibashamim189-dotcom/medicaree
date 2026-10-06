import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userName;
  final String userRole;
  final String userEmail;
  final String feedback;
  final DateTime? timestamp;

  FeedbackModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.feedback,
    this.timestamp,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userName: data['userName'] ?? 'Unknown User',
      userRole: data['userRole'] ?? 'Unknown',
      userEmail: data['userEmail'] ?? 'No Email',
      feedback: data['feedback'] ?? 'No content',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}