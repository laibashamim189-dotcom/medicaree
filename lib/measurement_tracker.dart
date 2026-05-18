import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeasurementTracker extends StatefulWidget {
  const MeasurementTracker({super.key});

  @override
  State<MeasurementTracker> createState() => _MeasurementTrackerState();
}

class _MeasurementTrackerState extends State<MeasurementTracker> {
  final TextEditingController _valController = TextEditingController();
  String selectedCategory = 'Blood Pressure';
  String unit = 'mmHg';

  // Local storage for history demo
  final List<Map<String, dynamic>> _history = [
    {'type': 'Blood Pressure', 'value': '120/80', 'unit': 'mmHg', 'date': '2026-05-15', 'time': '10:30 AM'},
    {'type': 'Blood Sugar', 'value': '95', 'unit': 'mg/dL', 'date': '2026-05-15', 'time': '08:00 AM'},
  ];

  void _addMeasurement() {
    if (_valController.text.isNotEmpty) {
      setState(() {
        _history.insert(0, {
          'type': selectedCategory,
          'value': _valController.text,
          'unit': unit,
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'time': DateFormat('hh:mm a').format(DateTime.now()),
        });
        _valController.clear();
      });
      FocusScope.of(context).unfocus(); // Close keyboard after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Measurement", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0), // Consistent Blue
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // INPUT SECTION
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.blue[800],
                  value: selectedCategory,
                  style: const TextStyle(color: Colors.white),
                  items: ['Blood Pressure', 'Blood Sugar', 'Body Weight']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCategory = val!;
                      if (val == 'Blood Pressure') unit = 'mmHg';
                      else if (val == 'Blood Sugar') unit = 'mg/dL';
                      else unit = 'kg';
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Category",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _valController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Enter Value ($unit)",
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: "e.g., 120",
                    hintStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Add to History", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // HISTORY LIST
          const Padding(
            padding: EdgeInsets.only(top: 25, left: 20, bottom: 10),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: const Icon(Icons.history, color: Color(0xFF1565C0)),
                    ),
                    title: Text(
                        "${item['value']} ${item['unit']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: Text("${item['type']} • ${item['date']} at ${item['time']}"),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}