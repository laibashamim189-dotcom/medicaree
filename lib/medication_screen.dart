import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
      firstDate: DateTime.now(),
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
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add Medication", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildDialogField(
                  _nameController, 
                  "Medicine Name", 
                  Icons.medication,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]'))],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildDialogField(_dosageController, "Dosage (e.g. 1 pill)", Icons.science),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: InputDecoration(
                    labelText: "Frequency",
                    prefixIcon: const Icon(Icons.repeat, color: brandBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
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
                _buildDialogField(
                  _stockController, 
                  "Stock (Optional)", 
                  Icons.inventory, 
                  keyboardType: TextInputType.number, 
                  isOptional: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveMedication,
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

  Future<void> _saveMedication() async {
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
      final String setDate = _dateController.text;
      final String setTime = _timeController.text;

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
        'time': setTime,
        'date': setDate,
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
      _nameController.clear();
      _dosageController.clear();
      _stockController.clear();
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
        title: const Text("Medication Reminders", style: TextStyle(color: Colors.white)),
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
              final dosage = data['dosage'] ?? "";
              final stockStr = data['stock'] ?? "";
              final int stockCount = stockStr.isNotEmpty ? int.tryParse(stockStr) ?? -1 : -1;

              return Dismissible(
                key: Key(doc.id),
                direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.transparent, child: const Icon(Icons.delete, color: Colors.grey)),
                onDismissed: (direction) => FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  color: Colors.grey[50],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: brandBlue.withOpacity(0.1), 
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
                                Text("Stock: $stockCount", style: TextStyle(fontSize: 12, fontWeight: stockCount < 3 ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandBlue.withOpacity(0.1), 
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

  Widget _buildDialogField(
    TextEditingController controller, 
    String hint, 
    IconData icon, 
    {TextInputType? keyboardType, 
    bool isOptional = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint, 
        prefixIcon: Icon(icon, color: brandBlue), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
      ),
      validator: validator ?? (v) {
        if (isOptional) return null;
        return (v == null || v.isEmpty) ? "Required" : null;
      },
    );
  }

  Widget _buildPickerField(TextEditingController controller, String hint, IconData icon, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}
