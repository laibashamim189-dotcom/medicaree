import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor_review_model.dart';
import '../view_models/doctor_review_view_model.dart';

class DoctorReviewScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorReviewViewModel(),
      child: _DoctorReviewContent(
        appointmentId: appointmentId,
        patientId: patientId,
        patientName: patientName,
        patientCondition: patientCondition,
        collectionName: collectionName,
      ),
    );
  }
}

class _DoctorReviewContent extends StatefulWidget {
  final String appointmentId;
  final String? patientId;
  final String patientName;
  final String patientCondition;
  final String collectionName;

  const _DoctorReviewContent({
    required this.appointmentId,
    this.patientId,
    required this.patientName,
    required this.patientCondition,
    required this.collectionName,
  });

  @override
  State<_DoctorReviewContent> createState() => _DoctorReviewContentState();
}

class _DoctorReviewContentState extends State<_DoctorReviewContent> {
  final _medsController = TextEditingController();
  final _activityController = TextEditingController();
  final _measurementController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  String _managedBy = 'Patient';
  bool _needsPhysicalCaregiver = false;

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final viewModel = context.read<DoctorReviewViewModel>();
    final existingRecs = await viewModel.fetchExistingData(
      collectionName: widget.collectionName,
      appointmentId: widget.appointmentId,
    );

    if (existingRecs != null && mounted) {
      setState(() {
        _medsController.text = existingRecs.meds;
        _activityController.text = existingRecs.activities;
        _measurementController.text = existingRecs.measurements;
        _systolicController.text = existingRecs.targetSystolic;
        _diastolicController.text = existingRecs.targetDiastolic;
        _managedBy = existingRecs.managedBy;
        _needsPhysicalCaregiver = existingRecs.needsPhysicalCaregiver;
      });
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

  Future<void> _handleSubmit(DoctorReviewViewModel viewModel) async {
    try {
      final recs = DoctorReviewRecommendation(
        meds: _medsController.text.trim(),
        activities: _activityController.text.trim(),
        measurements: _measurementController.text.trim(),
        targetSystolic: _systolicController.text.trim(),
        targetDiastolic: _diastolicController.text.trim(),
        managedBy: _managedBy,
        needsPhysicalCaregiver: _needsPhysicalCaregiver,
      );

      await viewModel.submitRecommendation(
        collectionName: widget.collectionName,
        appointmentId: widget.appointmentId,
        patientId: widget.patientId,
        recommendations: recs,
      );

      if (mounted) {
        final isEdit = viewModel.isEditMode;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit
              ? "Recommendations updated successfully!"
              : "Recommendations submitted successfully!"),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting: ${e.toString().replaceAll('Exception: ', '')}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DoctorReviewViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(viewModel.isEditMode ? "Edit Recommendations" : "Review Patient"),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: (viewModel.isSubmitting || viewModel.isLoading)
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
                    TextSpan(
                      text: "${widget.patientName}: ",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextSpan(
                      text: widget.patientCondition,
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
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
              value: _managedBy,
              items: ['Patient', 'Caregiver', 'Both']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _managedBy = val);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text("Patient needs a physical caregiver at home?"),
              value: _needsPhysicalCaregiver,
              onChanged: (val) {
                if (val != null) setState(() => _needsPhysicalCaregiver = val);
              },
              activeColor: brandBlue,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 35),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: brandBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _handleSubmit(viewModel),
              child: Text(
                viewModel.isEditMode ? "UPDATE RECOMMENDATIONS" : "SUBMIT RECOMMENDATIONS",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
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

  Widget _buildTextField(
      TextEditingController controller,
      String hint, {
        int maxLines = 3,
        TextInputType keyboardType = TextInputType.text,
      }) {
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