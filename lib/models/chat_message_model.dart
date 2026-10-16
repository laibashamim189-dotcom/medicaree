import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final Timestamp? timestamp;
  final bool isPrivate;
  final String? privateType;
  final String receiverId;
  final List<dynamic> deletedFor;
  final bool isUser; // Added for AI Chat compatibility

  ChatMessageModel({
    this.id = '',
    this.senderId = '',
    this.senderName = '',
    required this.text,
    this.timestamp,
    this.isPrivate = false,
    this.privateType,
    this.receiverId = '',
    this.deletedFor = const [],
    this.isUser = false, // Default to false (used for AI Chat)
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString().trim(),
      senderName: data['senderName'] ?? 'User',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] as Timestamp?,
      isPrivate: data['isPrivate'] ?? false,
      privateType: data['privateType'],
      receiverId: data['receiverId'] ?? '',
      deletedFor: data['deletedFor'] ?? [],
      isUser: false,
    );
  }
}
