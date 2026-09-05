import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalDirectoryScreen extends StatefulWidget {
  const MedicalDirectoryScreen({Key? key}) : super(key: key);

  @override
  State<MedicalDirectoryScreen> createState() => _MedicalDirectoryScreenState();
}

class _MedicalDirectoryScreenState extends State<MedicalDirectoryScreen> {
  final _doctorFormKey = GlobalKey<FormState>();
  final _caregiverFormKey = GlobalKey<FormState>();

  // Doctor Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // Caregiver Controllers
  final TextEditingController _cgNameController = TextEditingController();
  final TextEditingController _cgPhoneController = TextEditingController();
  String _selectedRelationship = 'Relative';
  final List<String> _relationships = ['Relative', 'Friend', 'Professional Nurse', 'Other'];

  bool _isLoading = false;
  int _selectedCategoryIndex = 0; // 0: Doctor, 1: Caregiver, 2: Appointments

  // Theme Color Matching Design
  final Color primaryTeal = const Color(0xFF489499);

  // Firestore Instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendDoctorRequest() async {
    if (!_doctorFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String currentUserId = _auth.currentUser?.uid ?? '';

      await _firestore.collection('connection_requests').add({
        'patientId': currentUserId,
        'doctorName': _nameController.text.trim(),
        'doctorEmail': _emailController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'reason': _reasonController.text.trim(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor request sent successfully!')),
        );
      }

      _nameController.clear();
      _emailController.clear();
      _specialtyController.clear();
      _reasonController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCaregiverRequest() async {
    if (!_caregiverFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String currentUserId = _auth.currentUser?.uid ?? '';

      await _firestore.collection('caregiver_requests').add({
        'patientId': currentUserId,
        'caregiverName': _cgNameController.text.trim(),
        'caregiverPhone': _cgPhoneController.text.trim(),
        'relationship': _selectedRelationship,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caregiver request sent successfully!')),
        );
      }

      _cgNameController.clear();
      _cgPhoneController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _reasonController.dispose();
    _cgNameController.dispose();
    _cgPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medical Directory',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Tab Selector
            Container(
              color: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryTab(0, Icons.medical_services, 'Doctor'),
                  _buildCategoryTab(1, Icons.person_add_alt_1, 'Caregiver'),
                  _buildCategoryTab(2, Icons.calendar_month, 'Appointments'),
                ],
              ),
            ),

            if (_selectedCategoryIndex == 0) _buildDoctorTab(),
            if (_selectedCategoryIndex == 1) _buildCaregiverTab(),
            if (_selectedCategoryIndex == 2) _buildAppointmentsPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _doctorFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Doctor Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _nameController,
              hintText: "Doctor's Name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _emailController,
              hintText: "Doctor's Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _specialtyController,
              hintText: "Specialty",
              icon: Icons.medical_services_outlined,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _reasonController,
              hintText: "Reason/Symptoms",
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _buildActionButton("Send Request", _sendDoctorRequest),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Sent Requests & Responses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildSentRequestsList('connection_requests', 'doctorName', 'specialty'),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _caregiverFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Caregiver Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _cgNameController,
              hintText: "Caregiver Full Name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _cgPhoneController,
              hintText: "Phone Number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRelationship,
              decoration: InputDecoration(
                labelText: "Relationship",
                prefixIcon: Icon(Icons.people_outline, color: primaryTeal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryTeal, width: 2),
                ),
              ),
              items: _relationships.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedRelationship = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            _buildActionButton("Send Request", _sendCaregiverRequest),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Caregiver Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildSentRequestsList('caregiver_requests', 'caregiverName', 'relationship'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsPlaceholder() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(child: Text("Appointments view coming soon")),
    );
  }

  Widget _buildCategoryTab(int index, IconData icon, String label) {
    final isSelected = _selectedCategoryIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 30,
              color: Colors.white,
            )
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (val) => val!.isEmpty ? 'Enter field' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryTeal),
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryTeal, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildSentRequestsList(String collectionName, String titleField, String subtitleField) {
    final String currentUserId = _auth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(collectionName)
          .where('patientId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No requests sent yet.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final String status = data['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: const Color(0xFFF3F5FC),
              elevation: 0,
              child: ListTile(
                title: Text(
                  data[titleField] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(data[subtitleField] ?? ''),
                trailing: _buildStatusBadge(status),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBD5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toLowerCase(),
        style: const TextStyle(
          color: Color(0xFFDA8D3C),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
