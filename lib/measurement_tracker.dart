import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MeasurementTrackerScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const MeasurementTrackerScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MeasurementTrackerScreen> createState() => _MeasurementTrackerScreenState();
}

class _MeasurementTrackerScreenState extends State<MeasurementTrackerScreen> {
  String _selectedCategory = 'Blood Pressure';
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  static const Color brandBlue = Color(0xFF1565C0);

  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  final List<String> _categories = [
    'Blood Pressure',
    'Body Weight',
    'Blood Sugar',
  ];

  Future<void> _recordMeasurement() async {
    if (widget.isReadOnly) return;
    if (_effectivePatientId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient ID not found")),
        );
      }
      return;
    }

    String displayValue = "";
    int? systolicValue;
    int? diastolicValue;

    if (_selectedCategory == 'Blood Pressure') {
      final s = int.tryParse(_systolicController.text.trim());
      final d = int.tryParse(_diastolicController.text.trim());

      if (s == null || d == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid numbers for Systolic & Diastolic")),
        );
        return;
      }

      systolicValue = s;
      diastolicValue = d;
      displayValue = "$s/$d mmHg";
    } else {
      if (_valueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter value")),
        );
        return;
      }
      String unit = _selectedCategory == 'Body Weight' ? 'kg' : 'mg/dL';
      displayValue = "${_valueController.text.trim()} $unit";
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance.collection('health_measurements').add({
        'patientId': _effectivePatientId,
        'category': _selectedCategory,
        'value': displayValue,
        'systolic': systolicValue,
        'diastolic': diastolicValue,
        'date': dateStr,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _systolicController.clear();
      _diastolicController.clear();
      _valueController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Measurement recorded successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Health Tracker", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solid Blue Header Input Section - Only show if not read only
            if (!widget.isReadOnly)
              Container(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
                decoration: const BoxDecoration(
                  color: brandBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Category",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: brandBlue,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      underline: Container(height: 1, color: Colors.white30),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    if (_selectedCategory == 'Blood Pressure')
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _systolicController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: const InputDecoration(
                                labelText: "Systolic",
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 14),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            child: TextField(
                              controller: _diastolicController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: const InputDecoration(
                                labelText: "Diastolic",
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 14),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      TextField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          labelText: "Enter Value (${_selectedCategory == 'Body Weight' ? 'kg' : 'mg/dL'})",
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                      ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: brandBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _recordMeasurement,
                        child: const Text(
                          "Record Measurement",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
               // If read only, just show a nice header
               Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(25, 40, 25, 40),
                decoration: const BoxDecoration(
                  color: brandBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Health History", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Viewing patient measurement records", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: Text(
                "History",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),

            const SizedBox(height: 15),

            if (_effectivePatientId.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('health_measurements')
                    .where('patientId', isEqualTo: _effectivePatientId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text("No records found.", style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final category = data['category'] ?? 'Measurement';
                      final value = data['value'] ?? '';
                      final date = data['date'] ?? '';
                      final systolic = data['systolic'] as int?;
                      final diastolic = data['diastolic'] as int?;

                      // Logic for Red Text: Systolic >= 140 OR Diastolic < 70 (adjust as needed)
                      bool isHighRisk = false;
                      if (category == 'Blood Pressure' && systolic != null && diastolic != null) {
                        if (systolic >= 140 || diastolic < 70) {
                          isHighRisk = true;
                        }
                      }

                      return Dismissible(
                        key: Key(doc.id),
                        direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.transparent,
                          child: const Icon(Icons.delete, color: Colors.grey),
                        ),
                        onDismissed: widget.isReadOnly ? null : (direction) {
                          FirebaseFirestore.instance
                              .collection('health_measurements')
                              .doc(doc.id)
                              .delete();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isHighRisk ? Colors.red.shade50 : brandBlue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.show_chart,
                                  color: isHighRisk ? Colors.red.shade400 : brandBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isHighRisk ? Colors.red.shade500 : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      category,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                date,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
