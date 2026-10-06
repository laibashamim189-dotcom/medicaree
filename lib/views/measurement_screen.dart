import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/measurement_model.dart';
import '../view_models/measurement_view_model.dart';

class MeasurementScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const MeasurementScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  late MeasurementViewModel _viewModel;
  static const Color brandBlue = Color(0xFF1565C0);

  final _dateController = TextEditingController();
  final _timeController1 = TextEditingController();
  final _timeController2 = TextEditingController();
  final _timeController3 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = MeasurementViewModel();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController1.dispose();
    _timeController2.dispose();
    _timeController3.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: brandBlue),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _buildPickerField(TextEditingController controller, String label, IconData icon, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: _inputDeco(label, icon),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  void _showEditMeasurementDialog(MeasurementModel item) {
    if (widget.isReadOnly) return;

    String selectedCategory = item.title;
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

    List<String> times = item.times;
    _timeController1.text = times.isNotEmpty ? times[0] : "";
    _timeController2.text = times.length > 1 ? times[1] : "";
    _timeController3.text = times.length > 2 ? times[2] : "";

    DateTime tempDate = DateFormat('yyyy-MM-dd').parse(item.date);
    _dateController.text = item.date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Measurement", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: _inputDeco("Category", Icons.category),
                  items: ['Blood Pressure', 'Blood Sugar', 'Body Weight'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: freqType,
                  decoration: _inputDeco("Frequency Type", Icons.calendar_month),
                  items: ['Once a day', 'Twice a day', '3 times a day', 'Everyday', 'Specific Dates'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
                    decoration: _inputDeco("Times per day", Icons.repeat),
                    items: ['Once a day', 'Twice a day', '3 times a day'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setDialogState(() => freqTimes = val!),
                  ),
                const SizedBox(height: 15),
                _buildPickerField(_dateController, "Date", Icons.calendar_today, () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      tempDate = picked;
                      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                }),
                const SizedBox(height: 15),
                _buildPickerField(_timeController1, "Time 1", Icons.access_time, () async {
                  final picked = await showTimePicker(context: context, initialTime: _viewModel.parseTime(_timeController1.text));
                  if (picked != null) {
                    setDialogState(() {
                      _timeController1.text = picked.format(context);
                    });
                  }
                }),
                if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') ...[
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController2, "Time 2", Icons.access_time, () async {
                    final picked = await showTimePicker(context: context, initialTime: _viewModel.parseTime(_timeController2.text));
                    if (picked != null) setDialogState(() => _timeController2.text = picked.format(context));
                  }),
                ],
                if (freqTimes == '3 times a day') ...[
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController3, "Time 3", Icons.access_time, () async {
                    final picked = await showTimePicker(context: context, initialTime: _viewModel.parseTime(_timeController3.text));
                    if (picked != null) setDialogState(() => _timeController3.text = picked.format(context));
                  }),
                ],
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () async {
                        List<String> timeStrings = [_timeController1.text];
                        if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') {
                          timeStrings.add(_timeController2.text);
                        }
                        if (freqTimes == '3 times a day') {
                          timeStrings.add(_timeController3.text);
                        }

                        await _viewModel.updateMeasurement(
                          docId: item.id,
                          patientId: widget.patientId ?? "",
                          category: selectedCategory,
                          frequencyType: freqType,
                          frequencyTimes: freqTimes,
                          dateStr: _dateController.text,
                          timeStrings: timeStrings,
                          tempDate: tempDate,
                          context: context,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Updated $selectedCategory reminder set successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
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
    );
  }

  void _showAddMeasurementDialog() {
    if (widget.isReadOnly) return;
    String selectedCategory = 'Blood Pressure';
    String selectedFrequencyType = 'Everyday';
    String selectedFrequency = 'Once a day';
    DateTime selectedStartDate = DateTime.now();
    List<DateTime> selectedDatesList = [];
    TimeOfDay selectedTime1 = TimeOfDay.now();
    TimeOfDay? selectedTime2;
    TimeOfDay? selectedTime3;

    _dateController.text = DateFormat('yyyy-MM-dd').format(selectedStartDate);
    _timeController1.text = selectedTime1.format(context);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Add Measurement", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: _inputDeco("Category", Icons.category),
                      items: ['Blood Pressure', 'Blood Sugar', 'Body Weight'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedFrequencyType,
                      decoration: _inputDeco("Frequency Type", Icons.calendar_month),
                      items: ['Once a day', 'Twice a day', '3 times a day', 'Everyday', 'Specific Dates'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFrequencyType = val!;
                          if (val == 'Once a day' || val == 'Twice a day' || val == '3 times a day') {
                            selectedFrequency = val!;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    if (selectedFrequencyType == 'Everyday' || selectedFrequencyType == 'Specific Dates')
                      DropdownButtonFormField<String>(
                        value: selectedFrequency,
                        decoration: _inputDeco("Times per day", Icons.repeat),
                        items: ['Once a day', 'Twice a day', '3 times a day'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedFrequency = val!;
                            if (selectedFrequency == 'Twice a day' && selectedTime2 == null) {
                              selectedTime2 = const TimeOfDay(hour: 20, minute: 0);
                              _timeController2.text = selectedTime2!.format(context);
                            }
                            if (selectedFrequency == '3 times a day') {
                              if (selectedTime2 == null) selectedTime2 = const TimeOfDay(hour: 14, minute: 0);
                              if (selectedTime3 == null) selectedTime3 = const TimeOfDay(hour: 20, minute: 0);
                              _timeController2.text = selectedTime2!.format(context);
                              _timeController3.text = selectedTime3!.format(context);
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 15),
                    if (selectedFrequencyType != 'Specific Dates')
                      _buildPickerField(_dateController, "Start Date", Icons.calendar_today, () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedStartDate = picked;
                            _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      })
                    else ...[
                      const Text("Select Dates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        children: [
                          ...selectedDatesList.map((date) => Chip(
                            label: Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontSize: 10)),
                            onDeleted: () => setDialogState(() => selectedDatesList.remove(date)),
                          )),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 16),
                            label: const Text("Add Date"),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  if (!selectedDatesList.any((d) => DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(picked))) {
                                    selectedDatesList.add(picked);
                                    selectedDatesList.sort();
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController1, "Time 1", Icons.access_time, () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime1);
                      if (picked != null) {
                        setDialogState(() {
                          selectedTime1 = picked;
                          _timeController1.text = picked.format(context);
                        });
                      }
                    }),
                    if (selectedFrequency == 'Twice a day' || selectedFrequency == '3 times a day') ...[
                      const SizedBox(height: 15),
                      _buildPickerField(_timeController2, "Time 2", Icons.access_time, () async {
                        final picked = await showTimePicker(context: context, initialTime: selectedTime2 ?? TimeOfDay.now());
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime2 = picked;
                            _timeController2.text = picked.format(context);
                          });
                        }
                      }),
                    ],
                    if (selectedFrequency == '3 times a day') ...[
                      const SizedBox(height: 15),
                      _buildPickerField(_timeController3, "Time 3", Icons.access_time, () async {
                        final picked = await showTimePicker(context: context, initialTime: selectedTime3 ?? TimeOfDay.now());
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime3 = picked;
                            _timeController3.text = picked.format(context);
                          });
                        }
                      }),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        ElevatedButton(
                          onPressed: _viewModel.isSaving
                              ? null
                              : () async {
                            setDialogState(() {});
                            await _viewModel.addMeasurement(
                              patientId: widget.patientId ?? "",
                              category: selectedCategory,
                              frequencyType: selectedFrequencyType,
                              frequencyTimes: selectedFrequency,
                              startDate: selectedStartDate,
                              selectedDatesList: selectedDatesList,
                              time1: selectedTime1,
                              time2: selectedTime2,
                              time3: selectedTime3,
                              context: context,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Measurement reminders set successfully"),
                                  backgroundColor: Colors.green,
                                ),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Measurement Reminders", style: TextStyle(color: Colors.white)),
            backgroundColor: brandBlue,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: StreamBuilder<List<MeasurementModel>>(
            stream: _viewModel.getMeasurementRemindersStream(widget.patientId ?? ""),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No measurement reminders found"));
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
                    onDismissed: (_) => _viewModel.deleteMeasurement(item.id),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: Colors.grey[50],
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.show_chart, color: brandBlue),
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
                                          style: const TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 12),
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
                          ],
                        ),
                        trailing: !widget.isReadOnly
                            ? IconButton(
                          icon: const Icon(Icons.edit, color: brandBlue, size: 24),
                          onPressed: () => _showEditMeasurementDialog(item),
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
            onPressed: _showAddMeasurementDialog,
            backgroundColor: brandBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}