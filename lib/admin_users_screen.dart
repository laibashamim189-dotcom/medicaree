import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF1A233A);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search name or role...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text("Registered Users", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  isSearching = false;
                  _searchController.clear();
                  searchQuery = "";
                } else {
                  isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users registered yet."));
          }

          // Filter users based on search query
          final filteredUsers = snapshot.data!.docs.where((doc) {
            final userData = doc.data() as Map<String, dynamic>;
            final String name = (userData['name'] ?? '').toString().toLowerCase();
            final String role = (userData['role'] ?? '').toString().toLowerCase();
            final String email = (userData['email'] ?? '').toString().toLowerCase();

            return name.contains(searchQuery) ||
                role.contains(searchQuery) ||
                email.contains(searchQuery);
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(child: Text("No matching users found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final userData = filteredUsers[index].data() as Map<String, dynamic>;
              final String name = userData['name'] ?? 'No Name';
              final String email = userData['email'] ?? 'No Email';
              final String role = userData['role'] ?? 'No Role';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(role),
                    child: Text(
                      role.isNotEmpty ? role[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(role),
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Colors.blue;
      case 'patient':
        return Colors.green;
      case 'caregiver':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
