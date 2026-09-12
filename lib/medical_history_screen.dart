import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String? patientId;
  const MedicalHistoryScreen({super.key, this.patientId});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If a patientId is passed (from doctor view), use it. Otherwise use current user.
    final String? effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search name, date or time...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text("Medical History", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = "";
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: effectivePatientId == null 
        ? const Center(child: Text("User not identified"))
        : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_history')
            .where('userId', isEqualTo: effectivePatientId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No history records found for this patient."));
          }

          var docs = snapshot.data!.docs;

          // Apply filtering based on search query
          if (_searchQuery.isNotEmpty) {
            docs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String title = (data['title'] ?? '').toString().toLowerCase();
              final String date = (data['date'] ?? '').toString().toLowerCase();
              final String time = (data['time'] ?? '').toString().toLowerCase();
              
              return title.contains(_searchQuery) || 
                     date.contains(_searchQuery) || 
                     time.contains(_searchQuery);
            }).toList();
          }

          if (docs.isEmpty) {
            return const Center(child: Text("No matching records found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String title = data['title'] ?? 'Record';
              final String category = (data['category'] ?? 'General').toUpperCase();
              final String status = data['status'] ?? 'Marked';
              final String date = data['date'] ?? '';
              final String time = data['time'] ?? '';
              
              // Check if status represents a completed action, even with "by Patient/Caregiver" suffix
              bool isSuccess = status.startsWith('Taken') || 
                               status.startsWith('Measured') || 
                               status.startsWith('Completed') || 
                               status.startsWith('Attended') || 
                               status.startsWith('Done');
              
              Color statusColor = isSuccess ? Colors.green : Colors.red;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.transparent,
                  child: const Icon(Icons.delete, color: Colors.grey),
                ),
                onDismissed: (direction) {
                  FirebaseFirestore.instance.collection('user_history').doc(doc.id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$title deleted")),
                  );
                },
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined, color: statusColor),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("$category\n$date at $time", style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
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
