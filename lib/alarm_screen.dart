import 'package:flutter/material.dart';
import 'notification_service.dart';

class AlarmScreen extends StatefulWidget {
  final Map<String, dynamic> payload;

  const AlarmScreen({super.key, required this.payload});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  String? _pendingAction; // Stores 'action_taken' or 'action_missed'

  @override
  Widget build(BuildContext context) {
    final String title = widget.payload['title'] ?? 'Reminder';
    final String type = (widget.payload['type'] ?? 'Reminder').toString();
    
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
              Icons.alarm,
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
              title,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _pendingAction == null 
                  ? _buildInitialButtons() 
                  : _buildSelectionButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialButtons() {
    return Column(
      key: const ValueKey('initial'),
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _pendingAction = 'action_taken';
            });
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
            setState(() {
              _pendingAction = 'action_missed';
            });
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
    );
  }

  Widget _buildSelectionButtons() {
    return Column(
      key: const ValueKey('selection'),
      children: [
        const Text(
          "Who is marking this?",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _finalSubmit('Patient'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            "Mark as Patient",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _finalSubmit('Caregiver'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            "Mark as Caregiver",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _pendingAction = null;
            });
          },
          child: const Text("Back", style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  void _finalSubmit(String performedBy) {
    NotificationService.handleActionLogic(
      widget.payload['fullPayload'] ?? '', 
      _pendingAction,
      performedBy: performedBy,
    );
    Navigator.pop(context);
  }
}
