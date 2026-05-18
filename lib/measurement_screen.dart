import 'package:flutter/material.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  // Store the default/selected times for the reminders
  Map<String, TimeOfDay> measurementReminders = {
    'Blood Pressure': const TimeOfDay(hour: 8, minute: 0),
    'Blood Sugar': const TimeOfDay(hour: 7, minute: 30),
    'Body Weight': const TimeOfDay(hour: 6, minute: 0),
  };

  // Function to show the clock and pick a time
  Future<void> _pickTime(BuildContext context, String category) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: measurementReminders[category]!,
    );
    if (picked != null) {
      setState(() {
        measurementReminders[category] = picked;
      });
      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$category reminder updated to ${picked.format(context)}"),
          backgroundColor: Colors.blue[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      appBar: AppBar(
        title: const Text("Measurement Reminders", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0), // Deep Blue Theme
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set Daily Reminders",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Choose the best time to check your vitals.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // List of Reminders
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildReminderItem("Blood Pressure", Icons.favorite, Colors.redAccent),
                _buildReminderItem("Blood Sugar", Icons.water_drop, Colors.blueAccent),
                _buildReminderItem("Body Weight", Icons.monitor_weight, Colors.teal),
              ],
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              child: const Text(
                "Save & Exit",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable widget for each reminder category
  Widget _buildReminderItem(String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "Reminder at: ${measurementReminders[title]!.format(context)}",
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit_calendar, color: Color(0xFF1565C0)),
            onPressed: () => _pickTime(context, title),
          ),
        ),
      ),
    );
  }
}