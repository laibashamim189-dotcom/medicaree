import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class MeasurementScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const MeasurementScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Color brandBlue = Color(0xFF1565C0);
  bool _isSaving = false;

  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? _auth.currentUser?.uid ?? "";
  }

  void _showAddMeasurementDialog() {
    if (widget.isReadOnly) return;
    String selectedCategory = 'Blood Pressure';
    String selectedFrequency = 'Once a day';
    DateTime selectedDate = DateTime.now(); 
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Add Measurement Reminder", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField(
                      label: "Category",
                      icon: Icons.category,
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['Blood Pressure', 'Blood Sugar', 'Body Weight', 'Heart Rate']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedCategory = val!),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDialogField(
                      label: "Frequency",
                      icon: Icons.repeat,
                      child: DropdownButton<String>(
                        value: selectedFrequency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['Once a day', 'Twice a day', '3 times a day']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedFrequency = val!),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDialogField(
                      label: "Start Date",
                      icon: Icons.calendar_today,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setDialogState(() => selectedDate = picked);
                        },
                        child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDialogField(
                      label: "Reminder Time",
                      icon: Icons.access_time,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) setDialogState(() => selectedTime = picked);
                        },
                        child: Text(selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : () async {
                    if (_effectivePatientId.isEmpty) return;
                    setDialogState(() => _isSaving = true);
                    try {
                      final scheduledDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      final docRef = await _firestore.collection('reminders').add({
                        'userId': _effectivePatientId,
                        'title': selectedCategory,
                        'type': 'measurement',
                        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'time': selectedTime.format(context),
                        'frequency': selectedFrequency,
                        'status': 'Pending',
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      await NotificationService.scheduleNotification(
                        id: docRef.id.hashCode,
                        title: selectedCategory, 
                        body: "Time to check your $selectedCategory",
                        scheduledDate: scheduledDateTime,
                        docId: docRef.id,
                        type: 'measurement',
                        userId: _effectivePatientId,
                        repeats: true,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Measurement reminder set for ${DateFormat.yMMMd().format(scheduledDateTime)}")),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error saving measurement reminder: $e");
                    } finally {
                      setDialogState(() => _isSaving = false);
                    }
                  },
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField({required String label, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: brandBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Measurement Reminders", style: TextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reminders')
            .where('userId', isEqualTo: _effectivePatientId)
            .where('type', isEqualTo: 'measurement')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No measurement reminders found"));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Measurement';
              final date = data['date'] ?? '';
              final time = data['time'] ?? '';
              final frequency = data['frequency'] ?? 'Once a day';

              return Dismissible(
                key: Key(doc.id),
                direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.transparent, child: const Icon(Icons.delete, color: Colors.grey)),
                onDismissed: widget.isReadOnly ? null : (direction) => _firestore.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                  color: Colors.grey[50],
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: brandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.show_chart, color: brandBlue),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$date at $time", style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
      floatingActionButton: widget.isReadOnly ? null : FloatingActionButton(
        onPressed: _showAddMeasurementDialog,
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
