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
  final _timeController1 = TextEditingController();
  final _timeController2 = TextEditingController();
  final _timeController3 = TextEditingController();
  final _dateController = TextEditingController();
  final _durationController = TextEditingController();
  
  String selectedActivityType = 'Walking';
  String selectedFrequencyType = 'Everyday';
  String selectedFrequency = 'Once a day';
  DateTime? _selectedDate;
  List<DateTime> _selectedDates = [];
  TimeOfDay? _selectedTime1;
  TimeOfDay? _selectedTime2;
  TimeOfDay? _selectedTime3;
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
    _timeController1.dispose();
    _timeController2.dispose();
    _timeController3.dispose();
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

  Future<void> _addSpecificDate(BuildContext context, StateSetter setDialogState) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setDialogState(() {
        if (!_selectedDates.any((d) => DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(picked))) {
          _selectedDates.add(picked);
          _selectedDates.sort();
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index, {StateSetter? setDialogState}) async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      void update() {
        if (index == 1) {
          _selectedTime1 = picked;
          _timeController1.text = picked.format(context);
        } else if (index == 2) {
          _selectedTime2 = picked;
          _timeController2.text = picked.format(context);
        } else if (index == 3) {
          _selectedTime3 = picked;
          _timeController3.text = picked.format(context);
        }
      }
      if (setDialogState != null) {
        setDialogState(update);
      } else {
        setState(update);
      }
    }
  }

  TimeOfDay _parseTimeString(String timeStr, BuildContext context) {
    try {
      final parts = timeStr.split(':');
      var hour = int.parse(parts[0]);
      final minuteParts = parts[1].split(' ');
      final minute = int.parse(minuteParts[0]);
      final isPm = timeStr.toLowerCase().contains('pm');
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  void _showEditActivityDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    _durationController.text = data['duration'] ?? "";
    _dateController.text = data['date'] ?? "";
    
    List<dynamic> times = [];
    if (data['times'] != null) {
      times = data['times'];
    } else if (data['time'] != null) {
      times = [data['time']];
    }

    _timeController1.text = times.isNotEmpty ? times[0] : "";
    _timeController2.text = times.length > 1 ? times[1] : "";
    _timeController3.text = times.length > 2 ? times[2] : "";

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

    try {
      _selectedDate = DateFormat('yyyy-MM-dd').parse(data['date']);
      if (times.isNotEmpty) _selectedTime1 = _parseTimeString(times[0], context);
      if (times.length > 1) _selectedTime2 = _parseTimeString(times[1], context);
      if (times.length > 2) _selectedTime3 = _parseTimeString(times[2], context);
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
                  const Text("Edit Activity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: data['title'] ?? 'Walking',
                    decoration: InputDecoration(
                      labelText: "Type", 
                      prefixIcon: const Icon(Icons.fitness_center, color: brandBlue), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    items: standardActivities.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) => setDialogState(() => selectedActivityType = val!),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: "Duration (e.g. 30 mins)", 
                      prefixIcon: const Icon(Icons.timer, color: brandBlue), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: freqType,
                    decoration: InputDecoration(
                      labelText: "Frequency Type",
                      prefixIcon: const Icon(Icons.calendar_month, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    items: ['Once a day', 'Twice a day', '3 times a day', 'Everyday', 'Specific Dates'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      items: ['Once a day', 'Twice a day', '3 times a day'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (v) => setDialogState(() => freqTimes = v!),
                    ),
                  const SizedBox(height: 15),
                  _buildPickerField(_dateController, "Date", Icons.calendar_today, () => _selectDate(context)),
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController1, "Time 1", Icons.access_time, () => _selectTime(context, 1, setDialogState: setDialogState)),

                  if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController2, "Time 2", Icons.access_time, () => _selectTime(context, 2, setDialogState: setDialogState)),
                  ],
                  
                  if (freqTimes == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController3, "Time 3", Icons.access_time, () => _selectTime(context, 3, setDialogState: setDialogState)),
                  ],

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          String actName = data['title'] ?? 'Activity';
                          String newFreq = freqType;
                          if (freqType == 'Everyday' || freqType == 'Specific Dates') {
                            newFreq = "$freqType ($freqTimes)";
                          }

                          List<String> timeStrings = [_timeController1.text];
                          List<TimeOfDay?> timesToSchedule = [_selectedTime1];

                          if (freqTimes == 'Twice a day' || freqTimes == '3 times a day') {
                            timeStrings.add(_timeController2.text);
                            timesToSchedule.add(_selectedTime2);
                          }
                          if (freqTimes == '3 times a day') {
                            timeStrings.add(_timeController3.text);
                            timesToSchedule.add(_selectedTime3);
                          }

                          for (var t in timesToSchedule) {
                            if (t == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select all required times")));
                              return;
                            }
                          }

                          await doc.reference.update({
                            'title': selectedActivityType,
                            'duration': _durationController.text.trim(),
                            'date': _dateController.text,
                            'times': timeStrings,
                            'frequency': newFreq,
                          });
                          
                          if (_selectedDate != null) {
                            for (int i = 0; i < timesToSchedule.length; i++) {
                              DateTime scheduleTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, timesToSchedule[i]!.hour, timesToSchedule[i]!.minute);
                              await NotificationService.scheduleNotification(
                                id: (doc.id.hashCode + i),
                                title: selectedActivityType,
                                body: "Time for $selectedActivityType",
                                scheduledDate: scheduleTime,
                                docId: doc.id,
                                type: 'activity',
                                userId: _effectivePatientId,
                              );
                            }
                          }
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("updated $selectedActivityType reminder set successfully"),
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
      ),
    );
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
                    decoration: InputDecoration(
                      labelText: "Type", 
                      prefixIcon: const Icon(Icons.fitness_center, color: brandBlue), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    items: standardActivities.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) => setDialogState(() => selectedActivityType = val!),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: "Duration (e.g. 30 mins)", 
                      prefixIcon: const Icon(Icons.timer, color: brandBlue), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedFrequencyType,
                    decoration: InputDecoration(
                      labelText: "Frequency Type",
                      prefixIcon: const Icon(Icons.calendar_month, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    items: ['Once a day', 'Twice a day', '3 times a day', 'Everyday', 'Specific Dates']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedFrequencyType = v!;
                        if (v == 'Once a day' || v == 'Twice a day' || v == '3 times a day') {
                          selectedFrequency = v!;
                        }
                      });
                      setState(() {
                        selectedFrequencyType = v!;
                        if (v == 'Once a day' || v == 'Twice a day' || v == '3 times a day') {
                          selectedFrequency = v!;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  if (selectedFrequencyType == 'Everyday' || selectedFrequencyType == 'Specific Dates')
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: InputDecoration(
                        labelText: "Times per day",
                        prefixIcon: const Icon(Icons.repeat, color: brandBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      items: ['Once a day', 'Twice a day', '3 times a day']
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) {
                        setDialogState(() => selectedFrequency = v!);
                        setState(() => selectedFrequency = v!);
                      },
                    ),
                  const SizedBox(height: 15),
                  if (selectedFrequencyType != 'Specific Dates')
                    _buildPickerField(_dateController, "Start Date", Icons.calendar_today, () => _selectDate(context))
                  else ...[
                    const Text("Select Dates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._selectedDates.map((date) => Chip(
                          label: Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontSize: 10)),
                          onDeleted: () => setDialogState(() => _selectedDates.remove(date)),
                        )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text("Add Date"),
                          onPressed: () => _addSpecificDate(context, setDialogState),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 15),
                  _buildPickerField(_timeController1, "Time 1", Icons.access_time, () => _selectTime(context, 1, setDialogState: setDialogState)),
                  
                  if (selectedFrequency == 'Twice a day' || selectedFrequency == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController2, "Time 2", Icons.access_time, () => _selectTime(context, 2, setDialogState: setDialogState)),
                  ],
                  
                  if (selectedFrequency == '3 times a day') ...[
                    const SizedBox(height: 15),
                    _buildPickerField(_timeController3, "Time 3", Icons.access_time, () => _selectTime(context, 3, setDialogState: setDialogState)),
                  ],

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      const SizedBox(width: 10),
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

    List<DateTime> datesToProcess = [];
    if (selectedFrequencyType != 'Specific Dates') {
      if (_selectedDate == null) return;
      datesToProcess.add(_selectedDate!);
    } else {
      if (_selectedDates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one date")));
        return;
      }
      datesToProcess.addAll(_selectedDates);
    }

    List<TimeOfDay?> timesToSchedule = [_selectedTime1];
    List<String> timeStrings = [_timeController1.text];

    if (selectedFrequency == 'Twice a day') {
      timesToSchedule.add(_selectedTime2);
      timeStrings.add(_timeController2.text);
    } else if (selectedFrequency == '3 times a day') {
      timesToSchedule.add(_selectedTime2);
      timeStrings.add(_timeController2.text);
      timesToSchedule.add(_selectedTime3);
      timeStrings.add(_timeController3.text);
    }

    for (var t in timesToSchedule) {
      if (t == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select all required times")));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final String actTitle = selectedActivityType;
      final String duration = _durationController.text.trim();

      for (DateTime date in datesToProcess) {
        final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        
        String displayFreq = selectedFrequencyType;
        if (selectedFrequencyType == 'Everyday' || selectedFrequencyType == 'Specific Dates') {
          displayFreq = "$selectedFrequencyType ($selectedFrequency)";
        }

        final docRef = await FirebaseFirestore.instance.collection('reminders').add({
          'userId': _effectivePatientId,
          'title': actTitle,
          'times': timeStrings,
          'date': formattedDate,
          'type': 'activity',
          'duration': duration,
          'frequency': displayFreq,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        for (int i = 0; i < timesToSchedule.length; i++) {
          TimeOfDay currentT = timesToSchedule[i]!;
          DateTime scheduleTime = DateTime(date.year, date.month, date.day, currentT.hour, currentT.minute);
          await NotificationService.scheduleNotification(
            id: (docRef.id.hashCode + i),
            title: actTitle, 
            body: "Time for $actTitle",
            scheduledDate: scheduleTime,
            docId: docRef.id,
            type: 'activity',
            userId: _effectivePatientId,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Activity reminders set successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _durationController.clear();
      _timeController1.clear();
      _timeController2.clear();
      _timeController3.clear();
      _selectedTime1 = null;
      _selectedTime2 = null;
      _selectedTime3 = null;
      _selectedDates.clear();
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
        title: const Text("Activities Reminders", style: TextStyle(color: Colors.white)), 
        backgroundColor: brandBlue, 
        iconTheme: const IconThemeData(color: Colors.white)
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reminders').where('userId', isEqualTo: _effectivePatientId).where('type', isEqualTo: 'activity').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No activities added"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              final duration = data['duration'] ?? "";
              
              List<String> times = [];
              if (data['times'] != null) {
                times = List<String>.from(data['times']);
              } else if (data['time'] != null) {
                times = [data['time']];
              }

              return Dismissible(
                key: Key(doc.id),
                direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
                onDismissed: (dir) => FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete(),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.grey[50],
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: brandBlue.withOpacity(0.1), 
                      child: const Icon(Icons.fitness_center, color: brandBlue)
                    ),
                    title: Text(
                      data['title'] ?? "Activity", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        if (duration.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: brandBlue.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text("Duration: $duration", style: const TextStyle(color: brandBlue, fontWeight: FontWeight.w600, fontSize: 14)),
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
                      onPressed: () => _showEditActivityDialog(doc),
                    ) : null,
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
    return TextFormField(
      controller: controller, 
      readOnly: true, 
      onTap: onTap, 
      decoration: InputDecoration(
        hintText: hint, 
        prefixIcon: Icon(icon, color: brandBlue), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
      ), 
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null
    );
  }
}
