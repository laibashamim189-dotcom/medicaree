import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class MedicationScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const MedicationScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  String selectedFrequency = 'Once a day';
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
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  void _showAddMedicationDialog() {
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
                const Text("Add Medication", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildDialogField(_nameController, "Medicine Name", Icons.medication),
                const SizedBox(height: 15),
                _buildDialogField(_dosageController, "Dosage (e.g., 1 Pill, 50mg)", Icons.vaccines),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: selectedFrequency,
                  decoration: InputDecoration(
                    labelText: "Frequency",
                    prefixIcon: const Icon(Icons.repeat, color: brandBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Once a day', 'Twice a day', '3 times a day']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedFrequency = v!),
                ),
                const SizedBox(height: 15),
                _buildPickerField(_dateController, "Start Date", Icons.calendar_today, () => _selectDate(context)),
                const SizedBox(height: 15),
                _buildPickerField(_timeController, "Reminder Time", Icons.access_time, () => _selectTime(context)),
                const SizedBox(height: 15),
                // Stock field made optional by passing isOptional: true
                _buildDialogField(_stockController, "Stock (Optional)", Icons.inventory, keyboardType: TextInputType.number, isOptional: true),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveMedication,
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
    );
  }

  Future<void> _saveMedication() async {
    if (widget.isReadOnly) return;
    if (!_formKey.currentState!.validate()) return;
    if (_effectivePatientId.isEmpty) return;
    if (_selectedTime == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date and Time")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final String medicineName = _nameController.text.trim();
      final String dosage = _dosageController.text.trim();
      DateTime scheduleTime = DateTime(
        _selectedDate!.year, 
        _selectedDate!.month, 
        _selectedDate!.day, 
        _selectedTime!.hour, 
        _selectedTime!.minute
      );

      final docRef = await FirebaseFirestore.instance.collection('reminders').add({
        'userId': _effectivePatientId,
        'title': medicineName,
        'dosage': dosage,
        'time': _timeController.text,
        'date': _dateController.text,
        'type': 'medication',
        'status': 'Pending',
        'frequency': selectedFrequency,
        'stock': _stockController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: medicineName,
        body: "Time to take your $medicineName ${dosage.isNotEmpty ? '($dosage)' : ''}",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'medication',
        userId: _effectivePatientId,
        repeats: true,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reminder set for ${DateFormat.yMMMd().add_jm().format(scheduleTime)}")),
        );
      }
      
      _nameController.clear();
      _dosageController.clear();
      _stockController.clear();
      _selectedTime = null;
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
      appBar: AppBar(
        title: const Text("Medications", style: TextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: widget.isReadOnly ? null : FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: _effectivePatientId)
            .where('type', isEqualTo: 'medication')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No medications added"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              final String dosage = data['dosage'] ?? "";
              final String stockStr = data['stock']?.toString() ?? "";
              final int stockCount = int.tryParse(stockStr) ?? -1;
              
              return Dismissible(
                key: Key(doc.id),
                direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.transparent, child: const Icon(Icons.delete, color: Colors.grey)),
                onDismissed: widget.isReadOnly ? null : (_) => FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  color: Colors.grey[50],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: brandBlue.withValues(alpha: 0.1), 
                      child: const Icon(Icons.medication, color: brandBlue)
                    ),
                    title: Text(data['title'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dosage.isNotEmpty)
                          Text("Dosage: $dosage", style: const TextStyle(color: brandBlue, fontWeight: FontWeight.w500)),
                        Text("${data['date']} at ${data['time']}"),
                        if (stockCount != -1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 14, color: stockCount < 3 ? Colors.red : Colors.grey[700]),
                                const SizedBox(width: 4),
                                Text(
                                  "Stock: $stockCount",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: stockCount < 3 ? FontWeight.bold : FontWeight.normal,
                                    color: stockCount < 3 ? Colors.red : Colors.grey[700],
                                  ),
                                ),
                                if (stockCount < 3)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text("Refill soon!", style: TextStyle(fontSize: 10, color: Colors.red, fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandBlue.withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Text(data['frequency'] ?? "", style: const TextStyle(color: brandBlue, fontSize: 12)),
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

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, bool isOptional = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) {
        if (isOptional) return null;
        return v!.isEmpty ? "Required" : null;
      },
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
