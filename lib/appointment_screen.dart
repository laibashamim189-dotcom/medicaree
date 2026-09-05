import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class AppointmentScreen extends StatefulWidget {
  final String? patientId;
  const AppointmentScreen({super.key, this.patientId});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  bool _isSaving = false;
  static const Color brandBlue = Color(0xFF1565C0);

  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  @override
  void dispose() {
    _docController.dispose();
    _specialtyController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: _selectedTime ?? TimeOfDay.now()
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  _buildPickerField(_dateController, "Select Date", Icons.calendar_today, () => _selectDate(context)),
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController, "Select Time", Icons.access_time, () => _selectTime(context)),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSaving ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            setDialogState(() => _isSaving = true);
                            await _saveAppointment();
                            if (mounted) setDialogState(() => _isSaving = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAppointment() async {
    if (_effectivePatientId.isEmpty) return;
    if (_selectedTime == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date and Time")));
      return;
    }

    try {
      DateTime scheduleTime = DateTime(
        _selectedDate!.year, 
        _selectedDate!.month, 
        _selectedDate!.day, 
        _selectedTime!.hour, 
        _selectedTime!.minute
      );

      final docRef = await FirebaseFirestore.instance.collection('reminders').add({
        'userId': _effectivePatientId,
        'title': "Appt: ${_docController.text.trim()}",
        'doctorName': _docController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'time': _timeController.text,
        'date': _dateController.text,
        'type': 'appointment',
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: "Appointment Reminder",
        body: "Meeting with ${_docController.text.trim()} at ${_timeController.text}",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'appointment',
        userId: _effectivePatientId,
        repeats: false,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appointment reminder set for ${DateFormat.yMMMd().add_jm().format(scheduleTime)}")),
        );
      }
      
      _docController.clear();
      _specialtyController.clear();
      _selectedTime = null;
    } catch (e) {
      debugPrint("Save Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Appointments", style: TextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => NotificationService.showTestNotification(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppointmentDialog,
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: _effectivePatientId)
            .where('type', isEqualTo: 'appointment')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No appointments scheduled"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.transparent, child: const Icon(Icons.delete, color: Colors.grey)),
                onDismissed: (_) => FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  color: Colors.grey[50],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: brandBlue.withValues(alpha: 0.1), 
                      child: const Icon(Icons.event, color: brandBlue)
                    ),
                    title: Text(data['doctorName'] ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${data['date']} at ${data['time']}"),
                        Text("Status: $status", style: TextStyle(color: status == 'Attended' ? Colors.green : brandBlue, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandBlue.withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Text(data['specialty'] ?? "Appt", style: const TextStyle(color: brandBlue, fontSize: 12)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildPickerField(TextEditingController controller, String hint, IconData icon, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}
