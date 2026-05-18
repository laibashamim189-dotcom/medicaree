import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Activity Data
  final List<Map<String, dynamic>> activities = [
    {'title': 'Meal Tracking', 'subtitle': 'Breakfast, Lunch, Dinner', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'title': 'Water Intake', 'subtitle': 'Goal: 2-3 Liters', 'icon': Icons.local_drink, 'color': Colors.blue},
    {'title': 'Walking', 'subtitle': 'Daily Step Count', 'icon': Icons.directions_walk, 'color': Colors.green},
    {'title': 'Exercise', 'subtitle': 'Gym or Home Workout', 'icon': Icons.fitness_center, 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Activity Reminders"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: CircleAvatar(
                backgroundColor: activity['color'].withOpacity(0.1),
                child: Icon(activity['icon'], color: activity['color']),
              ),
              title: Text(activity['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(activity['subtitle']),
              trailing: const Icon(Icons.add_alarm, color: Colors.blue),
              onTap: () => _showTimePickerDialog(context, activity['title']),
            ),
          );
        },
      ),
    );
  }

  // Logic to set the reminder time
  void _showTimePickerDialog(BuildContext context, String activityName) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // In a real app, you'd save this to Firebase/Local Notifications
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder set for $activityName at ${pickedTime.format(context)}"),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}