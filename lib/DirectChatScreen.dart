import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DirectChatScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;
  final String receiverName;

  const DirectChatScreen({
    super.key,
    required this.doctorId,
    required this.patientId,
    required this.receiverName,
  });

  static String getChatId(String id1, String id2) {
    List<String> ids = [id1, id2];
    ids.sort();
    return ids.join('_');
  }

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  late String chatId;
  late String receiverId;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    chatId = DirectChatScreen.getChatId(widget.doctorId, widget.patientId);
    receiverId = (currentUserId == widget.doctorId) ? widget.patientId : widget.doctorId;
    
    // Mark messages as read when entering the chat
    _markAsRead();
  }

  void _markAsRead() {
    FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'isRead': true,
    }).catchError((e) => debugPrint("Error marking as read: $e"));
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
      'isRead': false,
      'users': [widget.doctorId, widget.patientId],
    }, SetOptions(merge: true));
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text("Delete ${_selectedMessageIds.length} messages?"),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _performDelete();
                  Navigator.pop(context);
                },
                child: const Text("Delete for everyone", 
                  style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton(
                onPressed: () {
                  _performDelete();
                  Navigator.pop(context);
                },
                child: const Text("Delete for me", 
                  style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", 
                  style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _performDelete() async {
    if (_selectedMessageIds.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (String msgId in _selectedMessageIds) {
      batch.delete(FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(msgId));
    }

    await batch.commit();
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        leading: _selectedMessageIds.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedMessageIds.clear()),
              )
            : null,
        title: _selectedMessageIds.isEmpty
            ? Text(widget.receiverName)
            : Text("${_selectedMessageIds.length}"),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedMessageIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.green),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No messages yet."));

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == currentUserId;
                    final String msgId = doc.id;
                    final bool isSelected = _selectedMessageIds.contains(msgId);

                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _selectedMessageIds.add(msgId);
                        });
                      },
                      onTap: () {
                        if (_selectedMessageIds.isNotEmpty) {
                          setState(() {
                            if (isSelected) {
                              _selectedMessageIds.remove(msgId);
                            } else {
                              _selectedMessageIds.add(msgId);
                            }
                          });
                        }
                      },
                      child: Container(
                        color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? brandBlue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(data['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: brandBlue), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
