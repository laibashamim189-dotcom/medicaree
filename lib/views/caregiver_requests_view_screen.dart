import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caregiver_request_item.dart';
import '../view_models/caregiver_request_view_model.dart';

class CaregiverRequestsViewScreen extends StatelessWidget {
  const CaregiverRequestsViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CaregiverRequestsViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pending Patient Requests'),
            backgroundColor: const Color(0xFF4B9F90),
          ),
          body: StreamBuilder<List<CaregiverRequestItem>>(
            stream: viewModel.getRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No pending requests found.'));
              }

              final requests = snapshot.data!;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final item = requests[index];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("Patient: ${item.patientName}"),
                      subtitle: Text("Relationship: ${item.relationship}\nStatus: ${item.status}"),
                      trailing: item.status == 'pending'
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => viewModel.acceptRequest(item.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => viewModel.rejectRequest(item.id),
                          ),
                        ],
                      )
                          : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.status == 'accepted'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            color: item.status == 'accepted'
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
