import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/medication_model.dart';
import '../view_models/medication_view_model.dart';

class MedicationScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const MedicationScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  late MedicationViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _timeController2 = TextEditingController();
  final _timeController3 = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedTime2;
  TimeOfDay? _selectedTime3;

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _viewModel = MedicationViewModel();
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
    _timeController2.dispose();
    _timeController3.dispose();
    _viewModel.dispose();
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

  Future<void> _addSpecificDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _viewModel.addSpecificDate(picked);
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        if (index == 1) {
          _selectedTime = picked;
          _timeController.text = picked.format(context);
        } else if (index == 2) {
          _selectedTime2 = picked;
          _timeController2.text = picked.format(context);
        } else if (index == 3) {
          _selectedTime3 = picked;
          _timeController3.text = picked.format(context);
        }
      });
    }
  }

  void _showEditMedicationDialog(MedicationModel item) {
    _nameController.text = item.title;
    _dosageController.text = item.dosage;
    _stockController.text = item.stock;
    _dateController.text = item.date;

    final times = item.times;
    _timeController.text = times.isNotEmpty ? times[0] : "";
    _timeController2.text = times.length > 1 ? times[1] : "";
    _timeController3.text = times.length > 2 ? times[2] : "";

    String currentFreq = item.frequency;
    String freqType = 'Everyday';
    String freqTimes = 'Once a day';

    if (currentFreq.contains('Specific Dates')) {
      freqType = 'Specific Dates';
    } else if (currentFreq.contains('Everyday')) {
      freqType = 'Everyday';
    } else if (['Once a day', 'Twice a day', '3 times a day'].contains(currentFreq)) {
      freqType = currentFreq;
      freqTimes = currentFreq;
    }

    if (currentFreq.contains('Once a day')) freqTimes = 'Once a day';
    else if (currentFreq.contains('Twice a day')) freqTimes = 'Twice a day';
    else if (currentFreq.contains('3 times a day')) freqTimes = '3 times a day';

    try {
      _selectedDate = DateFormat('yyyy-MM-dd').parse(item.date);
      if (times.isNotEmpty) _selectedTime = _viewModel.parseTimeString(times[0]);
      if (times.length > 1) _selectedTime2 = _viewModel.parseTimeString(times[1]);
      if (times.length > 2) _selectedTime3 = _viewModel.parseTimeString(times[2]);
    } catch (e) {
      debugPrint("Parsing error: $e");
    }

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
                  const Text("Edit Medication", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildDialogField(_nameController, "Medicine Name", Icons.medication),
                  const SizedBox(height: 15),
                  _buildDialogField(_dosageController, "Dosage", Icons.science),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: freqType,
                    decoration: InputDecoration(
                      labelText: "Frequency Type",
                      prefixIcon: const Icon(Icons.calendar_month, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Once a day', 'Twice a day', '3 times a day', 'Everyday', 'Specific Dates']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        freqType = v!;
                        if (v == 'Once a day' || v == 'Twice a day' || v == '3 times a day') {
                          freqTimes = v!;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  if (freqType == 'Everyday' || freqType == 'Specific Dates')
                    DropdownButtonFormField<String>(
                      value: freqTimes,
                      decoration: InputDecoration(
                        labelText: "Times per day",
                        prefixIcon: const Icon(Icons.repeat, color: brandBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Once a day', 'Twice a day', '3 times a day']
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => freqTimes = v!),
                    ),
                  const SizedBox(height: 15),
                  _buildPickerField(_dateController, "Date", Icons.calendar_today, () => _selectDate(context)),
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController, "Time 1", Icons.access_time, () async {
                    await _selectTime(context, 1);
                    setDialogState(() {});
                  }),
                  if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController2, "Time 2", Icons.access_time, () async {
                      await _selectTime(context, 2);
                      setDialogState(() {});
                    }),
                  ],
                  if (freqTimes == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController3, "Time 3", Icons.access_time, () async {
                      await _selectTime(context, 3);
                      setDialogState(() {});
                    }),
                  ],
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          String medName = _nameController.text.trim();
                          List<String> timeStrings = [_timeController.text];
                          List<TimeOfDay?> timesToSchedule = [_selectedTime];

                          if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') {
                            timeStrings.add(_timeController2.text);
                            timesToSchedule.add(_selectedTime2);
                          }
                          if (freqTimes == '3 times a day') {
                            timeStrings.add(_timeController3.text);
                            timesToSchedule.add(_selectedTime3);
                          }

                          final error = await _viewModel.updateMedication(
                            docId: item.id,
                            patientId: widget.patientId,
                            name: medName,
                            dosage: _dosageController.text.trim(),
                            stock: _stockController.text.trim(),
                            dateText: _dateController.text,
                            selectedDate: _selectedDate,
                            freqType: freqType,
                            freqTimes: freqTimes,
                            timeStrings: timeStrings,
                            timesToSchedule: timesToSchedule,
                          );

                          if (mounted) {
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Updated $medName reminder set successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
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
      ),
    );
  }

  void _showAddMedicationDialog() {
    if (widget.isReadOnly) return;
    showDialog(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => AlertDialog(
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
                  _buildDialogField(
                    _nameController,
                    "Medicine Name",
                    Icons.medication,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]'))],
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 15),
                  _buildDialogField(_dosageController, "Dosage (e.g. 1 pill)", Icons.science),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _viewModel.selectedFrequencyType,
                    decoration: InputDecoration(
                      labelText: "Frequency Type",
                      prefixIcon: const Icon(Icons.calendar_month, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Once a day', 'Twice a day', '3 times a day', 'Everyday', 'Specific Dates']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _viewModel.setFrequencyType(v);
                    },
                  ),
                  const SizedBox(height: 15),
                  if (_viewModel.selectedFrequencyType == 'Everyday' || _viewModel.selectedFrequencyType == 'Specific Dates')
                    DropdownButtonFormField<String>(
                      value: _viewModel.selectedFrequency,
                      decoration: InputDecoration(
                        labelText: "Times per day",
                        prefixIcon: const Icon(Icons.repeat, color: brandBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Once a day', 'Twice a day', '3 times a day']
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _viewModel.setFrequency(v);
                      },
                    ),
                  const SizedBox(height: 15),
                  if (_viewModel.selectedFrequencyType != 'Specific Dates')
                    _buildPickerField(_dateController, "Start Date", Icons.calendar_today, () => _selectDate(context))
                  else ...[
                    const Text("Select Dates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._viewModel.selectedDates.map((date) => Chip(
                          label: Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontSize: 10)),
                          onDeleted: () => _viewModel.removeSpecificDate(date),
                        )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text("Add Date"),
                          onPressed: () => _addSpecificDate(context),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController, "Time 1", Icons.access_time, () => _selectTime(context, 1)),
                  if (_viewModel.selectedFrequency == 'Twice a day' || _viewModel.selectedFrequency == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController2, "Time 2", Icons.access_time, () => _selectTime(context, 2)),
                  ],
                  if (_viewModel.selectedFrequency == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController3, "Time 3", Icons.access_time, () => _selectTime(context, 3)),
                  ],
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
                        onPressed: _viewModel.isSaving ? null : _handleSaveMedication,
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

  Future<void> _handleSaveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await _viewModel.saveMedication(
      patientId: widget.patientId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      stock: _stockController.text.trim(),
      selectedDate: _selectedDate,
      time1: _selectedTime,
      time2: _selectedTime2,
      time3: _selectedTime3,
      time1Text: _timeController.text,
      time2Text: _timeController2.text,
      time3Text: _timeController3.text,
    );

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Medication reminders set successfully"),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _dosageController.clear();
        _stockController.clear();
        _timeController.clear();
        _timeController2.clear();
        _timeController3.clear();
        _selectedTime = null;
        _selectedTime2 = null;
        _selectedTime3 = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Medication Reminders", style: TextStyle(color: Colors.white)),
            backgroundColor: brandBlue,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          floatingActionButton: widget.isReadOnly
              ? null
              : FloatingActionButton(
            onPressed: _showAddMedicationDialog,
            backgroundColor: brandBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: StreamBuilder<List<MedicationModel>>(
            stream: _viewModel.getMedicationsStream(widget.patientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No medications added"));
              }

              final items = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  return Dismissible(
                    key: Key(item.id),
                    direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.transparent,
                      child: const Icon(Icons.delete, color: Colors.grey),
                    ),
                    onDismissed: (_) => _viewModel.deleteMedication(item.id),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      color: Colors.grey[50],
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: brandBlue.withValues(alpha: 0.1),
                          child: const Icon(Icons.medication, color: brandBlue),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            if (item.dosage.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.science, size: 14, color: brandBlue.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Dosage: ${item.dosage}",
                                    style: const TextStyle(color: brandBlue, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.date, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 8,
                                        children: item.times
                                            .map((t) => Text(
                                          t,
                                          style: const TextStyle(
                                            color: brandBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: brandBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.frequency,
                                style: const TextStyle(color: brandBlue, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (item.stockCount != -1)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 14,
                                      color: item.stockCount < 3 ? Colors.red : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Stock: ${item.stockCount}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: item.stockCount < 3 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: !widget.isReadOnly
                            ? IconButton(
                          icon: const Icon(Icons.edit, color: brandBlue, size: 24),
                          onPressed: () => _showEditMedicationDialog(item),
                        )
                            : null,
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

  Widget _buildDialogField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        TextInputType? keyboardType,
        bool isOptional = false,
        List<TextInputFormatter>? inputFormatters,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator ??
              (v) {
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
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}
