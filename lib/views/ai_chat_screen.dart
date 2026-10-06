import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/ai_chat_view_model.dart';

class AiChatScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isReadOnly;
  const AiChatScreen({super.key, this.onBack, this.isReadOnly = false});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AiChatViewModel>(context, listen: false).initHealthChatbot();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend(AiChatViewModel viewModel) {
    viewModel.sendMessage(_messageController.text, widget.isReadOnly);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiChatViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text("AI Health Assistant", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1565C0),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: viewModel.errorMessage.isNotEmpty
              ? Center(
            child: Text(
              viewModel.errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          )
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: viewModel.messages.length,
                  itemBuilder: (context, index) {
                    final msg = viewModel.messages[index];
                    return Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg.isUser ? Colors.blue[700] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              if (!widget.isReadOnly)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "Ask about health...",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _handleSend(viewModel),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF1565C0)),
                        onPressed: () => _handleSend(viewModel),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Chat is disabled in view-only mode.",
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}