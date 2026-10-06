import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ChatMessage_model.dart';

class AiChatViewModel extends ChangeNotifier {
  final List<ChatMessageModel> _messages = [
    ChatMessageModel(
      text: 'Hello! I am your AI Health Assistant. How can I help you today?',
      isUser: false,
    ),
  ];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  GenerativeModel? _model;
  ChatSession? _chat;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> initHealthChatbot() async {
    try {
      final String response = await rootBundle.loadString('assets/config.json');
      final Map<String, dynamic> data = jsonDecode(response);
      final String apiKey = data['gemini_api_key'] ?? '';

      if (apiKey.isEmpty) {
        _errorMessage = "API Key not found in config.json";
        notifyListeners();
        return;
      }

      const healthSystemPrompt = '''
You are an expert AI Health Assistant.
Provide concise, accurate advice on health, symptoms, diet, and medicines.
Politely decline any non-health queries.
''';

      _model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(healthSystemPrompt),
      );

      _chat = _model!.startChat();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = "Failed to load configuration: $e";
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text, bool isReadOnly) async {
    if (isReadOnly) return;
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _chat == null) return;

    _messages.add(ChatMessageModel(text: trimmedText, isUser: true));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _chat!.sendMessage(Content.text(trimmedText));
      _messages.add(
        ChatMessageModel(
          text: response.text ?? 'I could not process your health query. Please try again.',
          isUser: false,
        ),
      );
    } catch (e) {
      _messages.add(
        ChatMessageModel(
          text: "Error: $e",
          isUser: false,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}