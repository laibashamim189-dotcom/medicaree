import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ActivityScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const ActivityScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _dateController = TextEditingController();
  final _durationController = TextEditingController();
  
  String selectedActivityType = 'Walking';
  String selectedFrequency = 'Once a day';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  static const Color brandBlue = Color(0xFF1565C0);

  late String _effectivePatientId;

  final List<String> standardActivities = ['Walking', 'Exercise', 'Water Intake', 'Meal Tracking', 'Yoga', 'Cycling'];

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  void _showAddActivityDialog() {
    if (widget.isReadOnly) return;
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
                  const Text("Add Activity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedActivityType,
                    decoration: InputDecoration(labelText: "Type", prefixIcon: const Icon(Icons.fitness_center, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: standardActivities.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) => setDialogState(() => selectedActivityType = val!),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(labelText: "Duration (e.g. 30 mins)", prefixIcon: const Icon(Icons.timer, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 15),
                  _buildPickerField(_dateController, "Start Date", Icons.calendar_today, () => _selectDate(context)),
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController, "Time", Icons.access_time, () => _selectTime(context)),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveActivity,
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
      ),
    );
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_effectivePatientId.isEmpty) return;
    if (_selectedTime == null || _selectedDate == null) return;

    setState(() => _isSaving = true);
    try {
      final String setDate = _dateController.text;
      final String setTime = _timeController.text;
      final String activityTitle = _titleController.text.isEmpty ? selectedActivityType : _titleController.text.trim();
      
      final docRef = await FirebaseFirestore.instance.collection('reminders').add({
        'userId': _effectivePatientId,
        'title': activityTitle,
        'time': setTime,
        'date': setDate,
        'type': 'activity',
        'duration': _durationController.text.trim(),
        'frequency': selectedFrequency,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      DateTime scheduleTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      await NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: activityTitle, 
        body: "Time for $activityTitle",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'activity',
        userId: _effectivePatientId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reminder set for $setDate at $setTime"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Activities Reminders", style: TextStyle(color: Colors.white)), backgroundColor: brandBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reminders').where('userId', isEqualTo: _effectivePatientId).where('type', isEqualTo: 'activity').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No activities"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Dismissible(
                key: Key(doc.id),
                onDismissed: (dir) => FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.grey[50],
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: brandBlue.withOpacity(0.1), child: Icon(Icons.fitness_center, color: brandBlue)),
                    title: Text(data['title'] ?? "Activity", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${data['date']} at ${data['time']}\nDuration: ${data['duration'] ?? ''}"),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isReadOnly ? null : FloatingActionButton(onPressed: _showAddActivityDialog, backgroundColor: brandBlue, child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  Widget _buildPickerField(TextEditingController controller, String hint, IconData icon, VoidCallback onTap) {
    return TextFormField(controller: controller, readOnly: true, onTap: onTap, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => (v == null || v.isEmpty) ? "Required" : null);
  }
}
