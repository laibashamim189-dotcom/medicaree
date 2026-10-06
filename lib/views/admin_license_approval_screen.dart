import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../models/license_user_model.dart';
import '../view_models/admin_license_view_model.dart';

class AdminLicenseApprovalScreen extends StatefulWidget {
  const AdminLicenseApprovalScreen({super.key});

  @override
  State<AdminLicenseApprovalScreen> createState() => _AdminLicenseApprovalScreenState();
}

class _AdminLicenseApprovalScreenState extends State<AdminLicenseApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  static const Color darkBlue = Color(0xFF1A233A);
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      Provider.of<AdminLicenseViewModel>(context, listen: false)
          .setSearchText(_searchController.text);
    });
    _listenForNewRequests();
  }

  void _listenForNewRequests() {
    final viewModel = Provider.of<AdminLicenseViewModel>(context, listen: false);
    viewModel.getIncomingRequestsStream().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("New License Approval Request from ${data['name'] ?? 'User'}"),
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

  Future<void> _handleStatusUpdate(AdminLicenseViewModel viewModel, String docId, String newStatus, String name) async {
    bool success = await viewModel.updateLicenseStatus(docId: docId, newStatus: newStatus, name: name);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$name is now $newStatus"),
          backgroundColor: newStatus == 'APPROVED' ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmation(AdminLicenseViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Verification Request"),
        content: const Text("Are you sure you want to delete?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancel", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              bool success = await viewModel.deleteSelectedUsers();
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Records deleted successfully")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(AdminLicenseViewModel viewModel, String docId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reject Request"),
        content: Text("Are you sure you want to reject $name's license verification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancel", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleStatusUpdate(viewModel, docId, 'REJECTED', name);
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
    return Consumer<AdminLicenseViewModel>(
      builder: (context, viewModel, child) {
        bool hasSelection = viewModel.hasSelection;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            leading: hasSelection
                ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => viewModel.clearSelection(),
            )
                : (viewModel.isSearching
                ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                viewModel.toggleSearch();
                _searchController.clear();
              },
            )
                : null),
            title: viewModel.isSearching && !hasSelection
                ? TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Search name or date...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            )
                : Text(
              hasSelection ? "${viewModel.selectedCount}" : "License Verification",
              style: TextStyle(color: hasSelection ? brandBlue : Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: hasSelection ? Colors.white : darkBlue,
            elevation: hasSelection ? 2 : 0,
            iconTheme: IconThemeData(color: hasSelection ? brandBlue : Colors.white),
            actions: [
              if (hasSelection)
                IconButton(
                  icon: const Icon(Icons.delete, color: brandBlue),
                  onPressed: () => _showDeleteConfirmation(viewModel),
                )
              else ...[
                IconButton(
                  icon: Icon(viewModel.isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    viewModel.toggleSearch();
                    if (!viewModel.isSearching) _searchController.clear();
                  },
                ),
                if (!viewModel.isSearching)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onSelected: (value) => viewModel.setSelectedRole(value),
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
                Tab(text: "Incoming ${viewModel.selectedRole}s", icon: const Icon(Icons.pending_actions)),
                Tab(text: "Approved ${viewModel.selectedRole}s", icon: const Icon(Icons.verified_user)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList('PENDING', viewModel),
              _buildList('APPROVED', viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(String status, AdminLicenseViewModel viewModel) {
    return StreamBuilder<List<LicenseUserModel>>(
      stream: viewModel.getLicenseUsersStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(status == 'PENDING' ? Icons.inbox : Icons.check_circle_outline, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  status == 'PENDING' ? "No incoming ${viewModel.selectedRole} requests." : "No approved ${viewModel.selectedRole}s.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final filteredUsers = snapshot.data!.where((user) {
          if (viewModel.searchText.isEmpty) return true;
          final String name = user.name.toLowerCase();
          DateTime? time = status == 'PENDING' ? user.createdAt : user.verifiedAt;
          String dateStr = time != null ? DateFormat('MMM d, yyyy h:mm a').format(time).toLowerCase() : '';
          final queryStr = viewModel.searchText.toLowerCase();
          return name.contains(queryStr) || dateStr.contains(queryStr);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("No matching results found."));
        }

        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isWeb = screenWidth > 800;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: isWeb ? (screenWidth - 800) / 2 : 16, vertical: 16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final bool isSelected = viewModel.selectedIds.contains(user.id);

            DateTime? time = status == 'PENDING' ? user.createdAt : user.verifiedAt;
            String dateStr = time != null ? DateFormat('MMM d, yyyy h:mm a').format(time) : 'N/A';

            IconData roleIcon = Icons.person;
            if (viewModel.selectedRole == 'Doctor') {
              roleIcon = Icons.medical_services;
            } else if (viewModel.selectedRole == 'Pharmacist') {
              roleIcon = Icons.local_pharmacy;
            } else if (viewModel.selectedRole == 'Nurse') {
              roleIcon = Icons.health_and_safety;
            }

            return GestureDetector(
              onLongPress: () => viewModel.addSelection(user.id),
              onTap: () {
                if (viewModel.hasSelection) {
                  viewModel.toggleSelection(user.id);
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
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(
                          viewModel.selectedRole == 'Doctor'
                              ? (user.speciality ?? 'Specialist')
                              : (viewModel.selectedRole == 'Pharmacist' ? (user.pharmacyName ?? 'Pharmacy') : 'Professional Nurse'),
                        ),
                      ),
                      const Divider(),
                      Text("Email: ${user.email}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),

                      if (viewModel.selectedRole == 'Doctor') ...[
                        Text("License: ${user.licenseNumber ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ] else if (viewModel.selectedRole == 'Pharmacist') ...[
                        Text("Drug License: ${user.drugLicenseNumber ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        Text("Reg Number: ${user.pharmacistRegNumber ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        Text("Address: ${user.pharmacyAddress ?? 'N/A'}", style: const TextStyle(fontSize: 13)),
                      ] else if (viewModel.selectedRole == 'Nurse') ...[
                        Text("Nursing License: ${user.nursingLicenseNumber ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                      const SizedBox(height: 10),

                      if (user.certificateUrl != null && user.certificateUrl!.isNotEmpty) ...[
                        const Text("Certificate Proof:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showImageDialog(context, user.certificateUrl!),
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
                                user.certificateUrl!,
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
                              onPressed: () => _showRejectConfirmation(viewModel, user.id, user.name),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Reject", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _handleStatusUpdate(viewModel, user.id, 'APPROVED', user.name),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Approve", style: TextStyle(color: Colors.white)),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () => _handleStatusUpdate(viewModel, user.id, 'PENDING', user.name),
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