import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment_screen_model.dart';
import '../view_models/appointment_screen_view_model.dart';

class AppointmentScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;

  const AppointmentScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<AppointmentScreenViewModel>(context, listen: false);
      viewModel.initPatientId(widget.patientId);
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _docController.dispose();
    _specialtyController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, AppointmentScreenViewModel viewModel) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      viewModel.setSelectedDate(picked);
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectTime(BuildContext context, AppointmentScreenViewModel viewModel) async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      viewModel.setSelectedTime(picked);
      _timeController.text = picked.format(context);
    }
  }

  void _showEditAppointmentDialog(AppointmentScreenModel appointment, AppointmentScreenViewModel viewModel) {
    _docController.text = appointment.doctorName;
    _specialtyController.text = appointment.specialty;
    _dateController.text = appointment.date;
    _timeController.text = appointment.time;

    try {
      viewModel.setSelectedDate(DateFormat('yyyy-MM-dd').parse(appointment.date));
      viewModel.setSelectedTime(viewModel.parseTimeString(appointment.time));
    } catch (e) {
      debugPrint("Parsing error: $e");
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Appointment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildDialogField(_docController, "Doctor / Clinic Name", Icons.medical_services),
                const SizedBox(height: 15),
                _buildDialogField(_specialtyController, "Specialty / Reason", Icons.badge),
                const SizedBox(height: 15),
                _buildPickerField(_dateController, "Select Date", Icons.calendar_today, () => _selectDate(context, viewModel)),
                const SizedBox(height: 15),
                _buildPickerField(_timeController, "Select Time", Icons.access_time, () => _selectTime(context, viewModel)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        await viewModel.updateAppointment(
                          docId: appointment.id,
                          doctorName: _docController.text,
                          specialty: _specialtyController.text,
                          dateText: _dateController.text,
                          timeText: _timeController.text,
                        );

                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: brandBlue),
                      child: const Text("Update", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAppointmentDialog(AppointmentScreenViewModel viewModel) {
    if (widget.isReadOnly) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Schedule Appointment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildDialogField(_docController, "Doctor / Clinic Name", Icons.medical_services),
                const SizedBox(height: 15),
                _buildDialogField(_specialtyController, "Specialty / Reason", Icons.badge),
                const SizedBox(height: 15),
                _buildPickerField(_dateController, "Select Date", Icons.calendar_today, () => _selectDate(context, viewModel)),
                const SizedBox(height: 15),
                _buildPickerField(_timeController, "Select Time", Icons.access_time, () => _selectTime(context, viewModel)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: viewModel.isSaving
                          ? null
                          : () async {
                        if (_formKey.currentState!.validate()) {
                          final setDate = _dateController.text;
                          final setTime = _timeController.text;

                          await viewModel.saveAppointment(
                            doctorName: _docController.text,
                            specialty: _specialtyController.text,
                            dateText: setDate,
                            timeText: setTime,
                            onSuccess: () {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Reminder set for $setDate at $setTime"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: brandBlue),
                      child: const Text("Save", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentScreenViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Appointments", style: TextStyle(color: Colors.white)),
            backgroundColor: brandBlue,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: StreamBuilder<List<AppointmentScreenModel>>(
            stream: viewModel.getAppointmentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No appointments"));
              }

              final appointments = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return Dismissible(
                    key: Key(appointment.id),
                    direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                    onDismissed: (_) => viewModel.deleteAppointment(appointment.id),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.grey[50],
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: brandBlue.withOpacity(0.1),
                          child: const Icon(Icons.event, color: brandBlue),
                        ),
                        title: Text(appointment.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${appointment.date} at ${appointment.time}\nSpecialty: ${appointment.specialty}"),
                        trailing: !widget.isReadOnly
                            ? IconButton(
                          icon: const Icon(Icons.edit, color: brandBlue, size: 20),
                          onPressed: () => _showEditAppointmentDialog(appointment, viewModel),
                        )
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: widget.isReadOnly
              ? null
              : FloatingActionButton(
            onPressed: () => _showAddAppointmentDialog(viewModel),
            backgroundColor: brandBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildPickerField(TextEditingController controller, String hint, IconData icon, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}