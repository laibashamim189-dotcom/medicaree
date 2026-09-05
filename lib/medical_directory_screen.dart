import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class MedicalDirectoryScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;
  const MedicalDirectoryScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MedicalDirectoryScreen> createState() => _MedicalDirectoryScreenState();
}

class _MedicalDirectoryScreenState extends State<MedicalDirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _doctorFormKey = GlobalKey<FormState>();
  final _caregiverFormKey = GlobalKey<FormState>();
  final _apptFormKey = GlobalKey<FormState>();
  
  // Doctor Form Controllers
  final TextEditingController _docNameController = TextEditingController();
  final TextEditingController _docEmailController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();

  // Caregiver Form Controllers
  final TextEditingController _cgNameController = TextEditingController();
  final TextEditingController _cgEmailController = TextEditingController();
  String _relation = 'Relative';

  // Appointment Controllers
  final TextEditingController _apptDocNameController = TextEditingController();
  final TextEditingController _apptSpecialtyController = TextEditingController();
  final TextEditingController _apptDateController = TextEditingController();
  final TextEditingController _apptTimeController = TextEditingController();
  
  DateTime? _apptSelectedDate;
  TimeOfDay? _apptSelectedTime;

  bool _isSending = false;
  bool _isSavingAppt = false;
  static const Color brandBlue = Color(0xFF1565C0);

  late String _effectivePatientId;

  @override
  void initState() {
    super.initState();
    _effectivePatientId = widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _apptSelectedDate = DateTime.now();
    _apptDateController.text = DateFormat('yyyy-MM-dd').format(_apptSelectedDate!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _docNameController.dispose();
    _docEmailController.dispose();
    _specialtyController.dispose();
    _symptomsController.dispose();
    _cgNameController.dispose();
    _cgEmailController.dispose();
    _apptDocNameController.dispose();
    _apptSpecialtyController.dispose();
    _apptDateController.dispose();
    _apptTimeController.dispose();
    super.dispose();
  }

  Future<void> _sendDoctorRequest() async {
    if (widget.isReadOnly) return;
    if (!_doctorFormKey.currentState!.validate()) return;
    if (_effectivePatientId.isEmpty) return;

    setState(() => _isSending = true);

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_effectivePatientId).get();
      String patientName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? "Patient" : "Patient";

      await FirebaseFirestore.instance.collection('doctor_requests').add({
        'patientId': _effectivePatientId,
        'patientName': patientName,
        'doctorName': _docNameController.text.trim(),
        'doctorEmail': _docEmailController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'symptoms': _symptomsController.text.trim(),
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _docNameController.clear();
      _docEmailController.clear();
      _specialtyController.clear();
      _symptomsController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor request sent successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendCaregiverRequest() async {
    if (widget.isReadOnly) return;
    if (!_caregiverFormKey.currentState!.validate()) return;
    if (_effectivePatientId.isEmpty) return;

    setState(() => _isSending = true);

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_effectivePatientId).get();
      String patientName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? "Patient" : "Patient";

      await FirebaseFirestore.instance.collection('caregiver_requests').add({
        'patientId': _effectivePatientId,
        'patientName': patientName,
        'caregiverName': _cgNameController.text.trim(),
        'caregiverEmail': _cgEmailController.text.trim(),
        'relationship': _relation,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _cgNameController.clear();
      _cgEmailController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Caregiver request sent successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _saveAppointment() async {
    if (widget.isReadOnly) return;
    if (!_apptFormKey.currentState!.validate()) return;
    if (_effectivePatientId.isEmpty) return;
    if (_apptSelectedDate == null || _apptSelectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date and Time")));
      return;
    }

    setState(() => _isSavingAppt = true);

    try {
      final String doctorName = _apptDocNameController.text.trim();
      final scheduleTime = DateTime(
        _apptSelectedDate!.year,
        _apptSelectedDate!.month,
        _apptSelectedDate!.day,
        _apptSelectedTime!.hour,
        _apptSelectedTime!.minute,
      );

      final docRef = await FirebaseFirestore.instance.collection('reminders').add({
        'userId': _effectivePatientId,
        'title': "Appt: $doctorName",
        'doctorName': doctorName,
        'specialty': _apptSpecialtyController.text.trim(),
        'type': 'appointment',
        'date': _apptDateController.text,
        'time': _apptTimeController.text,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await NotificationService.scheduleNotification(
        id: docRef.id.hashCode,
        title: doctorName, // Pass doctor name for AlarmScreen display
        body: "Meeting with $doctorName at ${_apptTimeController.text}",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'appointment',
        userId: _effectivePatientId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appointment set for ${DateFormat.yMMMd().add_jm().format(scheduleTime)}")),
        );
      }

      _apptDocNameController.clear();
      _apptSpecialtyController.clear();
      _apptSelectedTime = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAppt = false);
    }
  }

  void _showScheduleAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: SingleChildScrollView(
            child: Form(
              key: _apptFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Schedule\nAppointment",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildDialogTextField(_apptDocNameController, "Doctor's Name", Icons.person),
                  const SizedBox(height: 15),
                  _buildDialogTextField(_apptSpecialtyController, "Specialty / Reason", Icons.medical_services),
                  const SizedBox(height: 15),
                  _buildDatePickerField(context, _apptDateController, "Select Date", Icons.calendar_today, (date) {
                    setDialogState(() => _apptSelectedDate = date);
                  }),
                  const SizedBox(height: 15),
                  _buildTimePickerField(context, _apptTimeController, "Select Time", Icons.access_time, (time) {
                    setDialogState(() => _apptSelectedTime = time);
                  }),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSavingAppt ? null : _saveAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        ),
                        child: _isSavingAppt 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: brandBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Medical Directory", style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services), text: "Doctor"),
            Tab(icon: Icon(Icons.person_add), text: "Caregiver"),
            Tab(icon: Icon(Icons.calendar_month), text: "Appointments"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDoctorTab(),
          _buildCaregiverTab(),
          _buildAppointmentsTab(),
        ],
      ),
      floatingActionButton: (_tabController.index == 2 && !widget.isReadOnly)
          ? FloatingActionButton(
              onPressed: _showScheduleAppointmentDialog,
              backgroundColor: brandBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildDoctorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isReadOnly) ...[
            const Text(
              "Request Doctor Connection",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _doctorFormKey,
              child: Column(
                children: [
                  _buildTextField(_docNameController, "Doctor's Name", Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_docEmailController, "Doctor's Email", Icons.email),
                  const SizedBox(height: 15),
                  _buildTextField(_specialtyController, "Specialty", Icons.badge),
                  const SizedBox(height: 15),
                  _buildTextField(_symptomsController, "Reason/Symptoms", Icons.assignment, maxLines: 3),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendDoctorRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSending 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Send Request", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
          ],
          const SizedBox(height: 20),
          const Text(
            "Sent Requests & Responses",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildRequestsList('doctor_requests', 'doctorName'),
        ],
      ),
    );
  }

  Widget _buildCaregiverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isReadOnly) ...[
            const Text(
              "Request Caregiver Connection",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _caregiverFormKey,
              child: Column(
                children: [
                  _buildTextField(_cgNameController, "Caregiver Full Name", Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_cgEmailController, "Caregiver Email", Icons.email),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: _relation,
                    decoration: InputDecoration(
                      labelText: "Relationship",
                      prefixIcon: const Icon(Icons.people, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Relative', 'Professional Nurse', 'Friend', 'Other']
                        .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                        .toList(),
                    onChanged: (value) => setState(() => _relation = value!),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendCaregiverRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSending 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Send Request", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
          ],
          const SizedBox(height: 20),
          const Text(
            "Caregiver Requests",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildRequestsList('caregiver_requests', 'caregiverName'),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_effectivePatientId.isEmpty) return const Center(child: Text("Please login"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reminders')
          .where('userId', isEqualTo: _effectivePatientId)
          .where('type', isEqualTo: 'appointment')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No appointments found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            
            return Dismissible(
              key: Key(doc.id),
              direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.transparent,
                child: const Icon(Icons.delete, color: Colors.grey),
              ),
              onDismissed: widget.isReadOnly ? null : (direction) {
                FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete();
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Colors.grey[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: brandBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.calendar_today, color: brandBlue),
                  ),
                  title: Text(data['doctorName'] ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${data['date']} at ${data['time']}"),
                    ],
                  ),
                  trailing: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active, color: brandBlue, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDatePickerField(BuildContext context, TextEditingController controller, String hint, IconData icon, Function(DateTime) onPicked) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _apptSelectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
          setState(() {
            controller.text = formattedDate;
          });
          onPicked(pickedDate);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildTimePickerField(BuildContext context, TextEditingController controller, String hint, IconData icon, Function(TimeOfDay) onPicked) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: _apptSelectedTime ?? TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() {
            controller.text = pickedTime.format(context);
          });
          onPicked(pickedTime);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildRequestsList(String collection, String nameField) {
    if (_effectivePatientId.isEmpty) return const Text("Please login to see requests");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('patientId', isEqualTo: _effectivePatientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No requests sent yet"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Pending';
            Map<String, dynamic>? recommendations = data['recommendations'] as Map<String, dynamic>?;
            
            return Dismissible(
              key: Key(doc.id),
              direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.transparent,
                child: const Icon(Icons.delete, color: Colors.grey),
              ),
              onDismissed: widget.isReadOnly ? null : (direction) {
                FirebaseFirestore.instance.collection(collection).doc(doc.id).delete();
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Colors.grey[50],
                child: Column(
                  children: [
                    ListTile(
                      title: Text(data[nameField] ?? "Request", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['specialty'] ?? data['relationship'] ?? ""),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: status == 'Approved' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'Approved' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (status == 'Approved' && recommendations != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: brandBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: brandBlue.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.recommend, size: 18, color: brandBlue),
                                  SizedBox(width: 8),
                                  Text(
                                    "Doctor's Recommendations:",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue),
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (recommendations['meds'] != null && recommendations['meds'].toString().isNotEmpty)
                                _buildRecommendationItem("Medications", recommendations['meds']),
                              if (recommendations['measurements'] != null && recommendations['measurements'].toString().isNotEmpty)
                                _buildRecommendationItem("Measurements", recommendations['measurements']),
                              if (recommendations['activities'] != null && recommendations['activities'].toString().isNotEmpty)
                                _buildRecommendationItem("Activities/Diet", recommendations['activities']),
                              if (recommendations['managedBy'] != null)
                                _buildRecommendationItem("Managed By", recommendations['managedBy']),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendationItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
