import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorReviewScreen extends StatefulWidget {
  final String appointmentId;
  final String? patientId; 
  final String patientName;
  final String patientCondition;
  final String collectionName; 

  const DoctorReviewScreen({
    super.key, 
    required this.appointmentId, 
    this.patientId,
    required this.patientName, 
    required this.patientCondition,
    this.collectionName = 'doctor_requests',
  });

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  final _medsController = TextEditingController();
  final _activityController = TextEditingController();
  final _measurementController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  String managedBy = 'Patient'; 
  bool needsPhysicalCaregiver = false;
  bool _isSubmitting = false;
  bool _isEditMode = false;

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _fetchExistingData();
  }

  Future<void> _fetchExistingData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.appointmentId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'Approved' && data['recommendations'] != null) {
          setState(() {
            _isEditMode = true;
            var recs = data['recommendations'];
            _medsController.text = recs['meds'] ?? "";
            _activityController.text = recs['activities'] ?? "";
            _measurementController.text = recs['measurements'] ?? "";
            _systolicController.text = recs['targetSystolic'] ?? "";
            _diastolicController.text = recs['targetDiastolic'] ?? "";
            managedBy = recs['managedBy'] ?? 'Patient';
            needsPhysicalCaregiver = recs['needsPhysicalCaregiver'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching existing data: $e");
    }
  }

  @override
  void dispose() {
    _medsController.dispose();
    _activityController.dispose();
    _measurementController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  Future<void> _submitRecommendation() async {
    if (widget.patientId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Patient ID not found.")));
       return;
    }

    setState(() => _isSubmitting = true);
    try {
      final String currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? "";

      Map<String, dynamic> updateData = {
        'status': 'Approved', 
        'doctorId': currentDoctorId,
        'recommendations': {
          'meds': _medsController.text.trim(),
          'activities': _activityController.text.trim(),
          'measurements': _measurementController.text.trim(),
          'targetSystolic': _systolicController.text.trim(),
          'targetDiastolic': _diastolicController.text.trim(),
          'managedBy': managedBy,
          'needsPhysicalCaregiver': needsPhysicalCaregiver,
        },
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        updateData['isEdited'] = true;
        updateData['lastEditedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.appointmentId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditMode ? "Recommendations updated successfully!" : "Recommendations submitted successfully!")
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error submitting: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Recommendations" : "Review Patient"), 
        backgroundColor: brandBlue, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Info Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FF),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE1EBF7)),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(text: "${widget.patientName}: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    TextSpan(text: widget.patientCondition, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            const Text("Provide Recommendations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),

            _buildSectionTitle("Medication Recommendation"),
            _buildTextField(_medsController, "e.g., Insulin 10 units before breakfast"),

            _buildSectionTitle("Target Blood Pressure *"),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField(_systolicController, "120", maxLines: 1, keyboardType: TextInputType.number),
                      const SizedBox(height: 4),
                      const Text("Systolic", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 20),
                  child: Text("|", style: TextStyle(fontSize: 30, color: Colors.grey, fontWeight: FontWeight.w300)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField(_diastolicController, "80", maxLines: 1, keyboardType: TextInputType.number),
                      const SizedBox(height: 4),
                      const Text("Diastolic", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),

            _buildSectionTitle("Measurement Plan"),
            _buildTextField(_measurementController, "e.g., Check BP twice daily"),

            _buildSectionTitle("Activity/Diet Recommendation"),
            _buildTextField(_activityController, "e.g., 30 mins morning walk, low salt"),

            const SizedBox(height: 20),
            const Text("System Management Suggestion", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Who should manage the app reminders?", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: managedBy,
              items: ['Patient', 'Caregiver', 'Both']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => managedBy = val!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text("Patient needs a physical caregiver at home?"),
              value: needsPhysicalCaregiver,
              onChanged: (val) => setState(() => needsPhysicalCaregiver = val!),
              activeColor: brandBlue,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 35),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: brandBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: _submitRecommendation,
              child: Text(_isEditMode ? "UPDATE RECOMMENDATIONS" : "SUBMIT RECOMMENDATIONS", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandBlue)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 3, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textAlign: maxLines == 1 ? TextAlign.center : TextAlign.start,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, 
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
