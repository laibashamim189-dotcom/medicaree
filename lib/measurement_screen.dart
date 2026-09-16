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
  
  final _dateController = TextEditingController();
  final _timeController1 = TextEditingController();
  final _timeController2 = TextEditingController();
  final _timeController3 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? _auth.currentUser?.uid ?? "";
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController1.dispose();
    _timeController2.dispose();
    _timeController3.dispose();
    super.dispose();
  }

  void _showEditMeasurementDialog(DocumentSnapshot doc) {
    if (widget.isReadOnly) return;
    final data = doc.data() as Map<String, dynamic>;
    
    String selectedCategory = data['title'] ?? 'Blood Pressure';
    String currentFreq = data['frequency'] ?? "";
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

    List<dynamic> times = [];
    if (data['times'] != null) {
      times = data['times'];
    } else if (data['time'] != null) {
      times = [data['time']];
    }

    _timeController1.text = times.isNotEmpty ? times[0] : "";
    _timeController2.text = times.length > 1 ? times[1] : "";
    _timeController3.text = times.length > 2 ? times[2] : "";

    DateTime tempDate = DateFormat('yyyy-MM-dd').parse(data['date']);
    _dateController.text = data['date'];

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
                  final picked = await showDatePicker(context: context, initialDate: tempDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2100));
                  if (picked != null) {
                    setDialogState(() {
                      tempDate = picked;
                      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                }),
                const SizedBox(height: 15),
                _buildPickerField(_timeController1, "Time 1", Icons.access_time, () async {
                  final picked = await showTimePicker(context: context, initialTime: _parseTime(_timeController1.text));
                  if (picked != null) {
                    setDialogState(() {
                      _timeController1.text = picked.format(context);
                    });
                  }
                }),
                if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') ...[
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController2, "Time 2", Icons.access_time, () async {
                    final picked = await showTimePicker(context: context, initialTime: _parseTime(_timeController2.text));
                    if (picked != null) setDialogState(() => _timeController2.text = picked.format(context));
                  }),
                ],
                if (freqTimes == '3 times a day') ...[
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController3, "Time 3", Icons.access_time, () async {
                    final picked = await showTimePicker(context: context, initialTime: _parseTime(_timeController3.text));
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
                        String displayFreq = freqType;
                        if (freqType == 'Everyday' || freqType == 'Specific Dates') {
                          displayFreq = "$freqType ($freqTimes)";
                        }

                        List<String> timeStrings = [_timeController1.text];
                        if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') {
                          timeStrings.add(_timeController2.text);
                        }
                        if (freqTimes == '3 times a day') {
                          timeStrings.add(_timeController3.text);
                        }

                        await doc.reference.update({
                          'title': selectedCategory,
                          'date': _dateController.text,
                          'times': timeStrings,
                          'frequency': displayFreq,
                        });

                        for (int i = 0; i < timeStrings.length; i++) {
                          TimeOfDay t = _parseTime(timeStrings[i]);
                          DateTime scheduleTime = DateTime(tempDate.year, tempDate.month, tempDate.day, t.hour, t.minute);
                          await NotificationService.scheduleNotification(
                            id: (doc.id.hashCode + i),
                            title: selectedCategory,
                            body: "Time to check your $selectedCategory",
                            scheduledDate: scheduleTime,
                            docId: doc.id,
                            type: 'measurement',
                            userId: _effectivePatientId,
                          );
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("updated $selectedCategory reminder set successfully"),
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

  TimeOfDay _parseTime(String timeStr) {
    try {
      return TimeOfDay.fromDateTime(DateFormat.jm().parse(timeStr));
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: brandBlue),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

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
                        final picked = await showDatePicker(context: context, initialDate: selectedStartDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
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
                              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
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
                          onPressed: _isSaving ? null : () async {
                            List<DateTime> datesToProcess = [];
                            if (selectedFrequencyType != 'Specific Dates') {
                              datesToProcess.add(selectedStartDate);
                            } else {
                              if (selectedDatesList.isEmpty) return;
                              datesToProcess.addAll(selectedDatesList);
                            }
                            List<TimeOfDay> times = [selectedTime1];
                            List<String> timeStrings = [selectedTime1.format(context)];
                            if (selectedFrequency == 'Twice a day' && selectedTime2 != null) {
                              times.add(selectedTime2!);
                              timeStrings.add(selectedTime2!.format(context));
                            }
                            else if (selectedFrequency == '3 times a day') {
                              if (selectedTime2 != null) {
                                times.add(selectedTime2!);
                                timeStrings.add(selectedTime2!.format(context));
                              }
                              if (selectedTime3 != null) {
                                times.add(selectedTime3!);
                                timeStrings.add(selectedTime3!.format(context));
                              }
                            }
                            setDialogState(() => _isSaving = true);
                            try {
                              String displayFreq = selectedFrequencyType;
                              if (selectedFrequencyType == 'Everyday' || selectedFrequencyType == 'Specific Dates') {
                                displayFreq = "$selectedFrequencyType ($selectedFrequency)";
                              }

                              for (DateTime date in datesToProcess) {
                                final String setDateStr = DateFormat('yyyy-MM-dd').format(date);
                                final docRef = await _firestore.collection('reminders').add({
                                  'userId': _effectivePatientId,
                                  'title': selectedCategory,
                                  'type': 'measurement',
                                  'date': setDateStr,
                                  'times': timeStrings,
                                  'frequency': displayFreq,
                                  'status': 'Pending',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                for (int i = 0; i < times.length; i++) {
                                  await NotificationService.scheduleNotification(
                                    id: (docRef.id.hashCode + i),
                                    title: selectedCategory, 
                                    body: "Time to check your $selectedCategory",
                                    scheduledDate: DateTime(date.year, date.month, date.day, times[i].hour, times[i].minute),
                                    docId: docRef.id,
                                    type: 'measurement',
                                    userId: _effectivePatientId,
                                  );
                                }
                              }
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Measurement reminders set successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) { debugPrint("Save Error: $e"); } 
                            finally { setDialogState(() => _isSaving = false); }
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

  Widget _buildPickerField(TextEditingController controller, String label, IconData icon, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: _inputDeco(label, icon),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Measurement Reminders", style: TextStyle(color: Colors.white)),
        backgroundColor: brandBlue,
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              List<String> times = [];
              if (data['times'] != null) {
                times = List<String>.from(data['times']);
              } else if (data['time'] != null) {
                times = [data['time']];
              }

              return Dismissible(
                key: Key(doc.id),
                direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                onDismissed: (dir) => _firestore.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.grey[50],
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: brandBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.show_chart, color: brandBlue),
                    ),
                    title: Text(
                      data['title'] ?? 'Measurement', 
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
                                  Text("${data['date']}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Wrap(
                                    spacing: 8,
                                    children: times.map((t) => Text(t, style: const TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
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
                            color: brandBlue.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(data['frequency'] ?? "", style: const TextStyle(color: brandBlue, fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    trailing: !widget.isReadOnly ? IconButton(
                      icon: const Icon(Icons.edit, color: brandBlue, size: 24),
                      onPressed: () => _showEditMeasurementDialog(doc),
                    ) : null,
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
