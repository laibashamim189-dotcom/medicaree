import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class AdminLicenseApprovalScreen extends StatefulWidget {
  const AdminLicenseApprovalScreen({super.key});

  @override
  State<AdminLicenseApprovalScreen> createState() => _AdminLicenseApprovalScreenState();
}

class _AdminLicenseApprovalScreenState extends State<AdminLicenseApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color darkBlue = const Color(0xFF1A233A);
  final Color brandBlue = const Color(0xFF1565C0);
  String selectedRole = 'Doctor'; 
  
  final Set<String> _selectedIds = {};
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
    _listenForNewRequests();
  }

  void _listenForNewRequests() {
    FirebaseFirestore.instance
        .collection('users')
        .where('licenseStatus', isEqualTo: 'PENDING')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("New License Approval Request from ${data['name']}"),
                backgroundColor: brandBlue,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(label: "VIEW", textColor: Colors.white, onPressed: () {}),
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(BuildContext context, DocumentSnapshot doc, String newStatus, String name) async {
    try {
      final String professionalId = doc.id;
      final String role = (doc.data() as Map<String, dynamic>)['role'] ?? 'Professional';

      await doc.reference.update({
        'licenseStatus': newStatus,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      String title = newStatus == 'APPROVED' ? "License Verified! ✅" : "License Rejected ❌";
      String body = newStatus == 'APPROVED' 
          ? "Congratulations $name! Your professional license has been verified."
          : "Sorry $name, your license verification was rejected. Please contact support.";

      await FirebaseFirestore.instance.collection('notifications').add({
        'toId': professionalId,
        'title': title,
        'body': body,
        'type': 'license_update',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$name is now $newStatus"),
            backgroundColor: newStatus == 'APPROVED' ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update Failed: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Verification Request"),
        content: const Text("Are you sure you want to delete?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text("Cancel", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              _deleteSelected();
              Navigator.of(dialogContext).pop();
            },
            child: Text("Delete", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final batch = FirebaseFirestore.instance.batch();
    for (var id in _selectedIds) {
      batch.delete(FirebaseFirestore.instance.collection('users').doc(id));
    }
    await batch.commit();
    setState(() {
      _selectedIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Records deleted successfully")),
      );
    }
  }

  void _showRejectConfirmation(BuildContext context, DocumentSnapshot doc, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reject Request"),
        content: Text("Are you sure you want to reject $name's license verification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text("Cancel", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _updateStatus(context, doc, 'REJECTED', name);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text("License Certificate"),
                backgroundColor: darkBlue,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Could not load image"),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = _selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: hasSelection
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              )
            : (_isSearching 
                ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isSearching = false))
                : null),
        title: Text(
          hasSelection ? "${_selectedIds.length}" : "License Verification", 
          style: TextStyle(color: hasSelection ? brandBlue : Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: hasSelection ? Colors.white : darkBlue,
        elevation: hasSelection ? 2 : 0,
        iconTheme: IconThemeData(color: hasSelection ? brandBlue : Colors.white),
        actions: [
          if (hasSelection)
            IconButton(
              icon: Icon(Icons.delete, color: brandBlue),
              onPressed: _showDeleteConfirmation,
            )
          else ...[
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) _searchController.clear();
                });
              },
            ),
            if (!_isSearching)
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onSelected: (value) => setState(() => selectedRole = value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Doctor', child: Text("Doctors")),
                  const PopupMenuItem(value: 'Pharmacist', child: Text("Pharmacists")),
                  const PopupMenuItem(value: 'Nurse', child: Text("Nurses")),
                ],
              ),
          ]
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: hasSelection ? brandBlue : Colors.white,
          labelColor: hasSelection ? brandBlue : Colors.white,
          unselectedLabelColor: hasSelection ? brandBlue.withOpacity(0.5) : Colors.white70,
          tabs: [
            Tab(text: "Incoming $selectedRole\s", icon: const Icon(Icons.pending_actions)),
            Tab(text: "Approved $selectedRole\s", icon: const Icon(Icons.verified_user)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('PENDING'),
          _buildList('APPROVED'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    Query query = FirebaseFirestore.instance.collection('users');

    if (selectedRole == 'Nurse') {
      query = query.where('role', isEqualTo: 'Caregiver').where('caregiverType', isEqualTo: 'Nurse');
    } else {
      query = query.where('role', isEqualTo: selectedRole);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.where('licenseStatus', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(status == 'PENDING' ? Icons.inbox : Icons.check_circle_outline, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  status == 'PENDING' ? "No incoming $selectedRole requests." : "No approved $selectedRole\s.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          if (_searchText.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final String name = (data['name'] ?? '').toString().toLowerCase();
          Timestamp? time = status == 'PENDING' ? (data['createdAt'] as Timestamp?) : (data['verifiedAt'] as Timestamp?);
          String dateStr = time != null ? DateFormat('MMM d, yyyy h:mm a').format(time.toDate()).toLowerCase() : '';
          final queryStr = _searchText.toLowerCase();
          return name.contains(queryStr) || dateStr.contains(queryStr);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("No matching results found."));
        }

        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isWeb = screenWidth > 800;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: isWeb ? (screenWidth - 800) / 2 : 16, vertical: 16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['name'] ?? 'Unknown';
            final String? certUrl = data['certificateUrl'];
            final String docId = doc.id;
            final bool isSelected = _selectedIds.contains(docId);
            
            Timestamp? time = status == 'PENDING' ? (data['createdAt'] as Timestamp?) : (data['verifiedAt'] as Timestamp?);
            String dateStr = time != null ? DateFormat('MMM d, yyyy h:mm a').format(time.toDate()) : 'N/A';

            IconData roleIcon = Icons.person;
            if (selectedRole == 'Doctor') roleIcon = Icons.medical_services;
            else if (selectedRole == 'Pharmacist') roleIcon = Icons.local_pharmacy;
            else if (selectedRole == 'Nurse') roleIcon = Icons.health_and_safety;

            return GestureDetector(
              onLongPress: () {
                setState(() {
                  _selectedIds.add(docId);
                });
              },
              onTap: () {
                if (_selectedIds.isNotEmpty) {
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
                elevation: isSelected ? 0 : 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: isSelected ? brandBlue : Colors.transparent, width: 2),
                ),
                color: isSelected ? brandBlue.withOpacity(0.05) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: status == 'APPROVED' ? Colors.green : darkBlue,
                          child: Icon(roleIcon, color: Colors.white, size: 28),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(selectedRole == 'Doctor' 
                          ? (data['speciality'] ?? 'Specialist') 
                          : (selectedRole == 'Pharmacist' ? (data['pharmacyName'] ?? 'Pharmacy') : 'Professional Nurse')),
                      ),
                      const Divider(),
                      Text("Email: ${data['email'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      
                      if (selectedRole == 'Doctor') ...[
                        Text("License: ${data['licenseNumber'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ] else if (selectedRole == 'Pharmacist') ...[
                        Text("Drug License: ${data['drugLicenseNumber'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        Text("Reg Number: ${data['pharmacistRegNumber'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        Text("Address: ${data['pharmacyAddress'] ?? 'N/A'}", style: const TextStyle(fontSize: 13)),
                      ] else if (selectedRole == 'Nurse') ...[
                        Text("Nursing License: ${data['nursingLicenseNumber'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                      const SizedBox(height: 10),

                      if (certUrl != null && certUrl.isNotEmpty) ...[
                        const Text("Certificate Proof:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showImageDialog(context, certUrl),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black12,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                certUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      Text(status == 'PENDING' ? "Applied: $dateStr" : "Approved: $dateStr", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'PENDING') ...[
                            TextButton.icon(
                              onPressed: () => _showRejectConfirmation(context, doc, name),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Reject", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _updateStatus(context, doc, 'APPROVED', name),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Approve", style: TextStyle(color: Colors.white)),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () => _updateStatus(context, doc, 'PENDING', name),
                              icon: const Icon(Icons.undo, size: 18),
                              label: const Text("Revoke Approval"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
