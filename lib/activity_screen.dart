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

  final List<String> standardActivities = [
    'Walking',
    'Exercise',
    'Water Intake',
    'Meal Tracking',
    'Yoga',
    'Cycling'
  ];

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
                  const Text("Add Activity Reminder", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedActivityType,
                    decoration: InputDecoration(
                      labelText: "Activity Type",
                      prefixIcon: const Icon(Icons.fitness_center, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: standardActivities
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedActivityType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: "Duration / Amount",
                      hintText: "e.g., 30 mins, 2 Liters",
                      prefixIcon: const Icon(Icons.timer_outlined, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedFrequency,
                    decoration: InputDecoration(
                      labelText: "Frequency",
                      prefixIcon: const Icon(Icons.repeat, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Once a day', 'Twice a day', '3 times a day']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedFrequency = v!),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: InputDecoration(
                      labelText: "Start Date",
                      prefixIcon: const Icon(Icons.calendar_today, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: () => _selectTime(context),
                    decoration: InputDecoration(
                      labelText: "Reminder Time",
                      prefixIcon: const Icon(Icons.access_time, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Custom Label (Optional)",
                      prefixIcon: const Icon(Icons.label, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveActivity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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

  Future<void> _saveActivity() async {
    if (widget.isReadOnly) return;
    if (!_formKey.currentState!.validate()) return;
    if (_effectivePatientId.isEmpty) return;
    if (_selectedTime == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date and Time")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final String activityTitle = _titleController.text.isEmpty ? selectedActivityType : _titleController.text.trim();
      
      final docRef = await FirebaseFirestore.instance.collection('reminders').add({
        'userId': _effectivePatientId,
        'title': activityTitle,
        'time': _timeController.text,
        'date': _dateController.text,
        'type': 'activity',
        'duration': _durationController.text.trim(),
        'frequency': selectedFrequency,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      DateTime scheduleTime = DateTime(
        _selectedDate!.year, 
        _selectedDate!.month, 
        _selectedDate!.day, 
        _selectedTime!.hour, 
        _selectedTime!.minute
      );

      await NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: activityTitle, 
        body: "Time for $activityTitle",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'activity',
        userId: _effectivePatientId,
        repeats: true,
      );

      if (mounted) Navigator.pop(context);
      _titleController.clear();
      _timeController.clear();
      _durationController.clear();
      _selectedTime = null;
    } catch (e) {
      debugPrint("Activity Save Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Activities", style: TextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: widget.isReadOnly ? null : FloatingActionButton(
        onPressed: _showAddActivityDialog,
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: _effectivePatientId)
            .where('type', isEqualTo: 'activity')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No activities added"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              final frequency = data['frequency'] ?? 'Once a day';
              final duration = data['duration'] ?? '';
              
              return Dismissible(
                key: Key(doc.id),
                direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.transparent,
                  child: const Icon(Icons.delete, color: Colors.grey),
                ),
                onDismissed: widget.isReadOnly ? null : (_) => FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  color: Colors.grey[50],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: brandBlue.withValues(alpha: 0.1),
                      child: Icon(_getIcon(data['title']), color: brandBlue),
                    ),
                    title: Text(data['title'] ?? "Activity", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${data['date'] ?? ''} at ${data['time']}"),
                        if (duration.toString().isNotEmpty)
                          Text("Duration/Amount: $duration", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(frequency, style: const TextStyle(color: brandBlue, fontSize: 10)),
                        const Icon(Icons.notifications_active, color: brandBlue, size: 20),
                      ],
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

  IconData _getIcon(String? title) {
    if (title == null) return Icons.fitness_center;
    final t = title.toLowerCase();
    if (t.contains('walk')) return Icons.directions_walk;
    if (t.contains('water')) return Icons.local_drink;
    if (t.contains('meal')) return Icons.restaurant;
    if (t.contains('yoga')) return Icons.self_improvement;
    if (t.contains('cycle')) return Icons.directions_bike;
    return Icons.fitness_center;
  }
}
