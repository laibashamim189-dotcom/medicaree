import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/alarm_view_model.dart';

class AlarmScreen extends StatefulWidget {
  final Map<String, dynamic> payload;

  const AlarmScreen({super.key, required this.payload});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlarmViewModel>(context, listen: false).initPayload(widget.payload);
    });
  }

  void _finalSubmit(AlarmViewModel viewModel, String performedBy) {
    viewModel.submitAction(performedBy);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmViewModel>(
      builder: (context, viewModel, child) {
        final payloadModel = viewModel.payloadModel;

        if (payloadModel == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D3B66),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0D3B66),
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
                  payloadModel.reminderText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  payloadModel.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Category: ${payloadModel.type.toUpperCase()}",
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
                    child: viewModel.pendingAction == null
                        ? _buildInitialButtons(viewModel)
                        : _buildSelectionButtons(viewModel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialButtons(AlarmViewModel viewModel) {
    return Column(
      key: const ValueKey('initial'),
      children: [
        ElevatedButton(
          onPressed: () => viewModel.setPendingAction('action_taken'),
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
          onPressed: () => viewModel.setPendingAction('action_missed'),
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

  Widget _buildSelectionButtons(AlarmViewModel viewModel) {
    return Column(
      key: const ValueKey('selection'),
      children: [
        const Text(
          "Who is marking this?",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _finalSubmit(viewModel, 'Patient'),
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
          onPressed: () => _finalSubmit(viewModel, 'Caregiver'),
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
          onPressed: () => viewModel.setPendingAction(null),
          child: const Text("Back", style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}