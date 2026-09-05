import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorReviewScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final String patientCondition;
  final String collectionName; // Added to support both collections

  const DoctorReviewScreen({
    super.key, 
    required this.appointmentId, 
    required this.patientName, 
    required this.patientCondition,
    this.collectionName = 'appointments', // Default for backward compatibility
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

  static const Color brandBlue = Color(0xFF1565C0);

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
    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.appointmentId).update({
        'status': 'Approved', 
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recommendations submitted successfully!")));
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
      appBar: AppBar(
        title: Text("Review: ${widget.patientName}"), 
        backgroundColor: brandBlue, 
        foregroundColor: Colors.white
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Condition: ${widget.patientCondition}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
            const Divider(height: 30),

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

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: brandBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: _submitRecommendation,
              child: const Text("Submit Recommendations", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
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
      decoration: InputDecoration(
        hintText: hint, 
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: maxLines == 1 ? const EdgeInsets.symmetric(horizontal: 10) : null,
      ),
    );
  }
}
