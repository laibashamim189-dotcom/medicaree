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

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.timestamp,
    required this.isPrivate,
    this.privateType,
    required this.receiverId,
    required this.deletedFor,
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
    );
  }
}