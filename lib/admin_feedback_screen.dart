import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final Set<String> _selectedIds = {};
  static const Color brandBlue = Color(0xFF1565C0);
  static const Color darkBlue = Color(0xFF1A233A);

  void _showDeleteDialog() {
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
            onPressed: () {
              _deleteSelected();
              Navigator.of(dialogContext, rootNavigator: true).pop();
            },
            child: const Text("Delete", 
                style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final batch = FirebaseFirestore.instance.batch();
    for (var id in _selectedIds) {
      batch.delete(FirebaseFirestore.instance.collection('feedback').doc(id));
    }
    await batch.commit();
    setState(() {
      _selectedIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = _selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: hasSelection
            ? IconButton(
                icon: const Icon(Icons.close, color: brandBlue),
                onPressed: () => setState(() => _selectedIds.clear()),
              )
            : null,
        title: Text(
          hasSelection ? "${_selectedIds.length} Selected" : "User Feedback", 
          style: TextStyle(color: hasSelection ? brandBlue : Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: hasSelection ? Colors.white : darkBlue,
        elevation: hasSelection ? 2 : 0,
        iconTheme: IconThemeData(color: hasSelection ? brandBlue : Colors.white),
        actions: [
          if (hasSelection)
            IconButton(
              icon: const Icon(Icons.delete, color: brandBlue),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No feedback received yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String docId = doc.id;
              final bool isSelected = _selectedIds.contains(docId);

              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    _selectedIds.add(docId);
                  });
                },
                onTap: () {
                  if (hasSelection) {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(docId);
                      } else {
                        _selectedIds.add(docId);
                      }
                    });
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
                                data['userName'] ?? 'Unknown User',
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
                                data['userRole'] ?? 'Unknown',
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
                          data['userEmail'] ?? 'No Email',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const Divider(height: 25),
                        const Text(
                          "Feedback:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data['feedback'] ?? 'No content',
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
  }
}
