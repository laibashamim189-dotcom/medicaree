import 'package:flutter/material.dart';

class DoctorReviewScreen extends StatefulWidget {
  final String patientName;
  final String patientCondition;

  const DoctorReviewScreen({super.key, required this.patientName, required this.patientCondition});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  // Recommendation Controllers
  final _medsController = TextEditingController();
  final _activityController = TextEditingController();
  final _measurementController = TextEditingController();

  // Caregiver Logic
  String managedBy = 'Patient'; // Default
  bool needsPhysicalCaregiver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Review: ${widget.patientName}"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Condition: ${widget.patientCondition}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const Divider(),

            _buildSectionTitle("Medication Recommendation"),
            _buildTextField(_medsController, "e.g., Insulin 10 units before breakfast"),

            _buildSectionTitle("Measurement Plan"),
            _buildTextField(_measurementController, "e.g., Check BP twice daily"),

            _buildSectionTitle("Activity/Diet Recommendation"),
            _buildTextField(_activityController, "e.g., 30 mins morning walk, low salt"),

            const SizedBox(height: 20),
            const Text("System Management Suggestion", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Who should manage the app reminders and track intake?"),
            DropdownButtonFormField<String>(
              value: managedBy,
              items: ['Patient', 'Caregiver', 'Both Patient & Caregiver']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => managedBy = val!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text("Patient needs a physical caregiver/attendant at home?"),
              value: needsPhysicalCaregiver,
              onChanged: (val) => setState(() => needsPhysicalCaregiver = val!),
              activeColor: Colors.blue,
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
              onPressed: _submitRecommendation,
              child: const Text("Submit Recommendations", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
    );
  }

  void _submitRecommendation() {
    // In your project, this would save to Firebase under 'recommendations'
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text("Recommendations sent to ${widget.patientName}.\nManaged by: $managedBy\nPhysical Caregiver: ${needsPhysicalCaregiver ? "Yes" : "No"}"),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Back to Dashboard
          }, child: const Text("OK"))
        ],
      ),
    );
  }
}