import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for easy formatting

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();

  // New Controllers for Date and Time
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String selectedFrequency = 'Every Day';

  // Function to pick Date
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Function to pick Time
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medication"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView( // Added to prevent overflow
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Medicine Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 15),

            // Frequency Dropdown
            DropdownButtonFormField<String>(
              value: selectedFrequency,
              decoration: const InputDecoration(
                labelText: "Frequency",
                border: OutlineInputBorder(),
              ),
              items: ['Every Day', 'Every Other Day', 'Specific Days']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (val) => setState(() => selectedFrequency = val!),
            ),
            const SizedBox(height: 15),

            // --- DATE PICKER FIELD ---
            TextField(
              controller: _dateController,
              readOnly: true, // User must use the picker
              decoration: const InputDecoration(
                labelText: "Start Date",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 15),

            // --- TIME PICKER FIELD ---
            TextField(
              controller: _timeController,
              readOnly: true, // User must use the picker
              decoration: const InputDecoration(
                labelText: "Reminder Time",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 15),

            // Refill / Stock Section
            const Text("Refill Reminder", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Current Stock (e.g. 30 pills)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
            ),
            const SizedBox(height: 30),

            // Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                // Submit logic here
              },
              child: const Text("Set Medication Reminder", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}