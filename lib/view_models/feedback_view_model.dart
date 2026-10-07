import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/feedback_model.dart';

class FeedbackViewModel extends ChangeNotifier {
  final TextEditingController feedbackController = TextEditingController();
  bool isSubmitting = false;

  Future<String?> submitFeedback() async {
    final text = feedbackController.text.trim();
    if (text.isEmpty) {
      return "Please enter some feedback";
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isSubmitting = false;
        notifyListeners();
        return "User not authenticated";
      }

      // Fetch user profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        final feedback = FeedbackModel(
          userId: user.uid,
          userName: userData['name'] ?? 'Unknown',
          userEmail: userData['email'] ?? 'No Email',
          userRole: userData['role'] ?? 'Unknown',
          feedbackText: text,
        );

        await FirebaseFirestore.instance
            .collection('feedback')
            .add(feedback.toMap());

        feedbackController.clear();
        isSubmitting = false;
        notifyListeners();
        return null;
      } else {
        isSubmitting = false;
        notifyListeners();
        return "User profile not found";
      }
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      return "Error: $e";
    }
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }
}