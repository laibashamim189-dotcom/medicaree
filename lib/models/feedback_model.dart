import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String feedbackText;
  final DateTime? timestamp;

  FeedbackModel({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.feedbackText,
    this.timestamp,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      userEmail: data['userEmail'] ?? 'No Email',
      userRole: data['userRole'] ?? 'Unknown',
      feedbackText: data['feedback'] ?? 'No content',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

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
