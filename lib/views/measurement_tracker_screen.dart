import 'package:flutter/material.dart';
import '../models/measurement_tracker_model.dart';
import '../view_models/measurement_tracker_view_model.dart';

class MeasurementTrackerScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const MeasurementTrackerScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MeasurementTrackerScreen> createState() => _MeasurementTrackerScreenState();
}

class _MeasurementTrackerScreenState extends State<MeasurementTrackerScreen> {
  late MeasurementTrackerViewModel _viewModel;
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = MeasurementTrackerViewModel();
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _valueController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleRecordMeasurement() async {
    final error = await _viewModel.recordMeasurement(
      patientId: widget.patientId ?? "",
      systolicText: _systolicController.text,
      diastolicText: _diastolicController.text,
      valueText: _valueController.text,
    );

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      } else {
        _systolicController.clear();
        _diastolicController.clear();
        _valueController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Measurement recorded successfully!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final effectiveId = _viewModel.getEffectivePatientId(widget.patientId);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Health Tracker", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: brandBlue,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          value: _viewModel.selectedCategory,
                          dropdownColor: brandBlue,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          underline: Container(height: 1, color: Colors.white30),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: _viewModel.categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _viewModel.setSelectedCategory(newValue);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_viewModel.selectedCategory == 'Blood Pressure')
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
                              labelText: "Enter Value (${_viewModel.selectedCategory == 'Body Weight' ? 'kg' : 'mg/dL'})",
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
                            onPressed: _handleRecordMeasurement,
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
                if (effectiveId.isNotEmpty)
                  StreamBuilder<List<MeasurementTrackerModel>>(
                    stream: _viewModel.getMeasurementsStream(widget.patientId ?? ""),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text("No records found.", style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      final items = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isHighRisk = item.isHighRisk;

                          return Dismissible(
                            key: Key(item.id),
                            direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.transparent,
                              child: const Icon(Icons.delete, color: Colors.grey),
                            ),
                            onDismissed: widget.isReadOnly ? null : (_) => _viewModel.deleteMeasurement(item.id),
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
                                          item.value,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isHighRisk ? Colors.red.shade500 : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.category,
                                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    item.date,
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
      },
    );
  }
}
