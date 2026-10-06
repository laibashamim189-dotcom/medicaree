import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/admin_feedback_view_model.dart';
import '../models/Adminfeedback_model.dart';

class AdminFeedbackScreen extends StatelessWidget {
  const AdminFeedbackScreen({super.key});

  static const Color brandBlue = Color(0xFF1565C0);
  static const Color darkBlue = Color(0xFF1A233A);

  void _showDeleteDialog(BuildContext context, AdminFeedbackViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Feedback"),
        content: const Text("Are you sure you want to delete?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            },
            child: const Text("Cancel",
                style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              bool success = await viewModel.deleteSelected();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Feedback deleted successfully")),
                );
              }
            },
            child: const Text("Delete",
                style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminFeedbackViewModel>(
      builder: (context, viewModel, child) {
        bool hasSelection = viewModel.hasSelection;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            leading: hasSelection
                ? IconButton(
              icon: const Icon(Icons.close, color: brandBlue),
              onPressed: () => viewModel.clearSelection(),
            )
                : null,
            title: Text(
              hasSelection ? "${viewModel.selectedCount} Selected" : "User Feedback",
              style: TextStyle(color: hasSelection ? brandBlue : Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: hasSelection ? Colors.white : darkBlue,
            elevation: hasSelection ? 2 : 0,
            iconTheme: IconThemeData(color: hasSelection ? brandBlue : Colors.white),
            actions: [
              if (hasSelection)
                IconButton(
                  icon: const Icon(Icons.delete, color: brandBlue),
                  onPressed: () => _showDeleteDialog(context, viewModel),
                ),
            ],
          ),
          body: StreamBuilder<List<FeedbackModel>>(
            stream: viewModel.feedbackStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No feedback received yet."));
              }

              final feedbacks = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: feedbacks.length,
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  final bool isSelected = viewModel.selectedIds.contains(feedback.id);

                  return GestureDetector(
                    onLongPress: () {
                      viewModel.addSelection(feedback.id);
                    },
                    onTap: () {
                      if (hasSelection) {
                        viewModel.toggleSelection(feedback.id);
                      }
                    },
                    child: Card(
                      elevation: isSelected ? 0 : 3,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isSelected ? brandBlue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      color: isSelected ? brandBlue.withOpacity(0.05) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    feedback.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: darkBlue,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: brandBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    feedback.userRole,
                                    style: const TextStyle(
                                      color: brandBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              feedback.userEmail,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            const Divider(height: 25),
                            const Text(
                              "Feedback:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              feedback.feedback,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}