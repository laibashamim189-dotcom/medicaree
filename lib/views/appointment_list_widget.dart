import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment_model.dart';
import '../view_models/appointment_list_view_model.dart';

class AppointmentListWidget extends StatelessWidget {
  final Color primaryBlue;

  const AppointmentListWidget({super.key, required this.primaryBlue});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.currentUser == null) {
          return const Center(child: Text("Please login"));
        }

        return StreamBuilder<List<AppointmentModel>>(
          stream: viewModel.getAppointmentsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "No appointments found",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final appointments = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];

                return Dismissible(
                  key: Key(appointment.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.transparent,
                    child: const Icon(Icons.delete, color: Colors.grey),
                  ),
                  onDismissed: (_) {
                    viewModel.deleteAppointment(appointment.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: primaryBlue.withOpacity(0.1),
                          child: Icon(Icons.person, color: primaryBlue, size: 30),
                        ),
                        title: Text(
                          appointment.doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(
                              appointment.specialty,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: primaryBlue),
                                const SizedBox(width: 5),
                                Text(
                                  appointment.date,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 15),
                                Icon(Icons.access_time, size: 16, color: primaryBlue),
                                const SizedBox(width: 5),
                                Text(
                                  appointment.time,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}