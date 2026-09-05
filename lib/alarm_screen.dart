import 'package:flutter/material.dart';
import 'notification_service.dart';

class AlarmScreen extends StatelessWidget {
  final Map<String, dynamic> payload;

  const AlarmScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final String title = payload['title'] ?? 'Reminder';
    final String type = (payload['type'] ?? 'Reminder').toString();
    
    String reminderText = "Time for Reminder!";
    if (type.toLowerCase() == 'medication') {
      reminderText = "Time for Medication!";
    } else if (type.toLowerCase() == 'measurement') {
      reminderText = "Time for Measurement!";
    } else if (type.toLowerCase() == 'activity') {
      reminderText = "Time for Activity!";
    } else if (type.toLowerCase() == 'appointment') {
      reminderText = "Time for Appointment!";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B66), // Dark blue background
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.alarm, // Changed to alarm icon to match requested UI
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 30),
            Text(
              reminderText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title, // This now displays the specific name (e.g., Panadol, Blood Pressure, Dr. Smith)
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Category: ${type.toUpperCase()}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      NotificationService.handleActionLogic(
                        payload['fullPayload'] ?? '', 
                        'action_taken'
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D3B66),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "DONE",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      NotificationService.handleActionLogic(
                        payload['fullPayload'] ?? '',
                        'action_missed'
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "DISMISS",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
