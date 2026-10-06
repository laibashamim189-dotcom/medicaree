import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message_model.dart';
import '../view_models/direct_chat_view_model.dart';

class DirectChatScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;
  final String receiverName;
  final bool isReadOnly;

  static String? activeChatId;

  const DirectChatScreen({
    super.key,
    required this.doctorId,
    required this.patientId,
    required this.receiverName,
    this.isReadOnly = false,
  });

  static String getChatId(String id1, String id2) => DirectChatViewModel.getChatId(id1, id2);

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    DirectChatScreen.activeChatId = DirectChatScreen.getChatId(widget.doctorId, widget.patientId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DirectChatViewModel>(context, listen: false).init(
        docId: widget.doctorId,
        patId: widget.patientId,
        recName: widget.receiverName,
        readOnly: widget.isReadOnly,
      );
    });
  }

  @override
  void dispose() {
    final String currentChatId = DirectChatScreen.getChatId(widget.doctorId, widget.patientId);
    if (DirectChatScreen.activeChatId == currentChatId) {
      DirectChatScreen.activeChatId = null;
    }
    _messageController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(DirectChatViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete message?", style: TextStyle(fontSize: 16, color: Colors.black54)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actionsPadding: const EdgeInsets.only(right: 15, bottom: 10),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  viewModel.deleteForEveryone();
                },
                child: const Text("Delete for everyone", style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  viewModel.deleteForMe();
                },
                child: const Text("Delete for me", style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectChatViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            leading: viewModel.selectedMessageIds.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => viewModel.clearSelection(),
            )
                : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                DirectChatScreen.activeChatId = null;
                Navigator.pop(context);
              },
            ),
            title: viewModel.selectedMessageIds.isEmpty
                ? Text(widget.receiverName)
                : Text("${viewModel.selectedMessageIds.length}"),
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            actions: [
              if (viewModel.selectedMessageIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _showDeleteDialog(viewModel),
                ),
            ],
          ),
          body: viewModel.isLoadingStatus
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              if (viewModel.showTabs) _buildToggleBar(viewModel),
              if (viewModel.showTabs && viewModel.activeTab == 1 && viewModel.currentUserRole.toLowerCase() == 'doctor')
                _buildDoctorTargetSelector(viewModel),
              Expanded(
                child: StreamBuilder<List<ChatMessageModel>>(
                  stream: viewModel.getMessagesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No messages here."));
                    }

                    final messages = snapshot.data!;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMe = msg.senderId == viewModel.currentUserId;
                        final bool isSelected = viewModel.selectedMessageIds.contains(msg.id);

                        String rawText = msg.text;
                        String tagLabel = "";
                        String displayText = rawText;

                        if (rawText.endsWith(" [Caregiver]")) {
                          tagLabel = "Caregiver";
                          displayText = rawText.replaceAll(" [Caregiver]", "");
                        } else if (rawText.endsWith(" [Patient]")) {
                          tagLabel = "Patient";
                          displayText = rawText.replaceAll(" [Patient]", "");
                        }

                        return GestureDetector(
                          onLongPress: () => viewModel.toggleMessageSelection(msg.id),
                          onTap: () {
                            if (viewModel.selectedMessageIds.isNotEmpty) {
                              viewModel.toggleMessageSelection(msg.id);
                            }
                          },
                          child: Container(
                            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? brandBlue : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (tagLabel.isNotEmpty && viewModel.showTabs && viewModel.activeTab == 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          tagLabel,
                                          style: TextStyle(
                                            color: isMe ? Colors.lightGreenAccent[400] : Colors.green[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      displayText,
                                      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (!widget.isReadOnly)
                _buildInputArea(viewModel)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: const Text(
                    "Read-only access. Management belongs to patient.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleBar(DirectChatViewModel viewModel) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _toggleTab(viewModel, 0, "Group Chat"),
          _toggleTab(viewModel, 1, "Private Chat"),
        ],
      ),
    );
  }

  Widget _toggleTab(DirectChatViewModel viewModel, int index, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => viewModel.setActiveTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: viewModel.activeTab == index ? brandBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: viewModel.activeTab == index ? brandBlue : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorTargetSelector(DirectChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("With Patient"),
            selected: viewModel.doctorPrivateTarget == 0,
            onSelected: (selected) {
              if (selected) viewModel.setDoctorPrivateTarget(0);
            },
            selectedColor: brandBlue.withOpacity(0.2),
            checkmarkColor: brandBlue,
          ),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text("With Caregiver"),
            selected: viewModel.doctorPrivateTarget == 1,
            onSelected: (selected) {
              if (selected) viewModel.setDoctorPrivateTarget(1);
            },
            selectedColor: brandBlue.withOpacity(0.2),
            checkmarkColor: brandBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(DirectChatViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: (viewModel.showTabs && viewModel.activeTab == 0) ? "Type a group message..." : "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: brandBlue),
            onPressed: () {
              viewModel.sendMessage(_messageController.text);
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }
}