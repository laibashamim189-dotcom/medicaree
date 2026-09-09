import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';
import 'DirectChatScreen.dart';
import 'payment_screen.dart';

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
  
  final TextEditingController _docNameController = TextEditingController();
  final TextEditingController _docEmailController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();

  final TextEditingController _cgNameController = TextEditingController();
  final TextEditingController _cgEmailController = TextEditingController();
  String _relation = 'Relative';

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
    _tabController.addListener(() => setState(() {}));
    _apptSelectedDate = DateTime.now();
    _apptDateController.text = DateFormat('yyyy-MM-dd').format(_apptSelectedDate!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _docNameController.dispose(); _docEmailController.dispose(); _specialtyController.dispose(); _symptomsController.dispose();
    _cgNameController.dispose(); _cgEmailController.dispose();
    _apptDocNameController.dispose(); _apptSpecialtyController.dispose(); _apptDateController.dispose(); _apptTimeController.dispose();
    super.dispose();
  }

  Future<void> _deleteRequest(String collection, String docId) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
  }

  Future<void> _saveAppointment() async {
    if (widget.isReadOnly || !_apptFormKey.currentState!.validate()) return;
    if (_effectivePatientId.isEmpty) return;
    if (_apptSelectedDate == null || _apptSelectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date and Time")));
      return;
    }

    setState(() => _isSavingAppt = true);
    try {
      final String doctorName = _apptDocNameController.text.trim();
      final scheduleTime = DateTime(_apptSelectedDate!.year, _apptSelectedDate!.month, _apptSelectedDate!.day, _apptSelectedTime!.hour, _apptSelectedTime!.minute);
      
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
        title: "Appointment Reminder",
        body: "Meeting with $doctorName at ${_apptTimeController.text}",
        scheduledDate: scheduleTime,
        docId: docRef.id,
        type: 'appointment',
        userId: _effectivePatientId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment scheduled successfully!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSavingAppt = false);
    }
  }

  Future<void> _sendDoctorRequest() async {
    if (widget.isReadOnly || !_doctorFormKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_effectivePatientId).get();
      String patientName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? "Patient" : "Patient";
      await FirebaseFirestore.instance.collection('doctor_requests').add({
        'patientId': _effectivePatientId, 'patientName': patientName,
        'doctorName': _docNameController.text.trim(), 'doctorEmail': _docEmailController.text.trim(),
        'specialty': _specialtyController.text.trim(), 'symptoms': _symptomsController.text.trim(),
        'status': 'Pending', 'timestamp': FieldValue.serverTimestamp(),
      });
      _docNameController.clear(); _docEmailController.clear(); _specialtyController.clear(); _symptomsController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor request sent!")));
    } catch (e) { debugPrint("Error: $e"); } finally { if (mounted) setState(() => _isSending = false); }
  }

  Future<void> _sendCaregiverRequest() async {
    if (widget.isReadOnly || !_caregiverFormKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_effectivePatientId).get();
      String patientName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? "Patient" : "Patient";
      await FirebaseFirestore.instance.collection('caregiver_requests').add({
        'patientId': _effectivePatientId, 'patientName': patientName,
        'caregiverName': _cgNameController.text.trim(), 'caregiverEmail': _cgEmailController.text.trim(),
        'relationship': _relation, 'status': 'Pending', 'timestamp': FieldValue.serverTimestamp(),
      });
      _cgNameController.clear(); _cgEmailController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Caregiver request sent!")));
    } catch (e) { debugPrint("Error: $e"); } finally { if (mounted) setState(() => _isSending = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: brandBlue, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Medical Directory", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          tabs: const [Tab(icon: Icon(Icons.medical_services), text: "Doctor"), Tab(icon: Icon(Icons.person_add), text: "Caregiver"), Tab(icon: Icon(Icons.calendar_month), text: "Appointments")],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildDoctorTab(), _buildCaregiverTab(), _buildAppointmentsTab()]),
      floatingActionButton: (_tabController.index == 2 && !widget.isReadOnly) 
          ? FloatingActionButton(onPressed: _showScheduleAppointmentDialog, backgroundColor: brandBlue, child: const Icon(Icons.add, color: Colors.white)) 
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
            const Text("Request Doctor Connection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Form(key: _doctorFormKey, child: Column(children: [
              _buildTextField(_docNameController, "Doctor's Name", Icons.person), const SizedBox(height: 15),
              _buildTextField(_docEmailController, "Doctor's Email", Icons.email), const SizedBox(height: 15),
              _buildTextField(_specialtyController, "Specialty", Icons.badge), const SizedBox(height: 15),
              _buildTextField(_symptomsController, "Reason/Symptoms", Icons.assignment, maxLines: 2), const SizedBox(height: 25),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSending ? null : _sendDoctorRequest, style: ElevatedButton.styleFrom(backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ])),
            const SizedBox(height: 30), const Divider(),
          ],
          const Text("Sent Requests & Responses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildDoctorRequestsList(),
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
            const Text("Request Caregiver Connection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Form(key: _caregiverFormKey, child: Column(children: [
              _buildOriginalStyleField(_cgNameController, "Caregiver Full Name", Icons.person), const SizedBox(height: 15),
              _buildOriginalStyleField(_cgEmailController, "Caregiver Email", Icons.email), const SizedBox(height: 15),
              DropdownButtonFormField<String>(value: _relation, decoration: InputDecoration(labelText: "Relationship", prefixIcon: const Icon(Icons.people, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))), items: ['Relative', 'Professional Nurse', 'Friend', 'Other'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(), onChanged: (v) => setState(() => _relation = v!)),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSending ? null : _sendCaregiverRequest, style: ElevatedButton.styleFrom(backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ])),
            const SizedBox(height: 30), const Divider(),
          ],
          const Text("Caregiver Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildCaregiverRequestsList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reminders').where('userId', isEqualTo: _effectivePatientId).where('type', isEqualTo: 'appointment').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No appointments found"));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return Dismissible(
              key: Key(doc.id),
              direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.transparent, child: const Icon(Icons.delete, color: Colors.grey)),
              onDismissed: (_) => FirebaseFirestore.instance.collection('reminders').doc(doc.id).delete(),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.grey[50],
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: brandBlue.withOpacity(0.1), child: const Icon(Icons.calendar_today, color: brandBlue)),
                  title: Text(doc['doctorName'] ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${doc['date']} at ${doc['time']}"),
                  trailing: const Icon(Icons.notifications_active, color: brandBlue, size: 20),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoctorRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctor_requests').where('patientId', isEqualTo: _effectivePatientId).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No requests found"));
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index]; var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Pending'; Map<String, dynamic>? recommendations = data['recommendations'] as Map<String, dynamic>?;
            return Dismissible(
              key: Key(doc.id), direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
              onDismissed: (_) => _deleteRequest('doctor_requests', doc.id),
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.grey)),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0, color: Colors.grey[50],
                child: Column(children: [
                  ListTile(title: Text(data['doctorName'] ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(data['specialty'] ?? ""), trailing: _buildStatusBadge(status)),
                  if (status == 'Approved' && recommendations != null) _buildRecommendationsBox(data, recommendations),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCaregiverRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('caregiver_requests').where('patientId', isEqualTo: _effectivePatientId).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No requests found"));
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return Dismissible(
              key: Key(doc.id), direction: widget.isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
              onDismissed: (_) => _deleteRequest('caregiver_requests', doc.id),
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.grey)),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0, color: Colors.grey[50],
                child: ListTile(title: Text(doc['caregiverName'] ?? "Caregiver", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(doc['relationship'] ?? ""), trailing: _buildStatusBadge(doc['status'] ?? 'Pending')),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendationsBox(Map<String, dynamic> data, Map<String, dynamic> recs) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE1EBF7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.check_circle, color: brandBlue, size: 20), SizedBox(width: 8), Text("Doctor's Recommendations:", style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue, fontSize: 15))]),
          const Divider(height: 20),
          _buildRecItem("Medications", recs['meds'] ?? "N/A"),
          _buildRecItem("Measurements", recs['measurements'] ?? "N/A"),
          _buildRecItem("Activities/Diet", recs['activities'] ?? "N/A"),
          _buildRecItem("Managed By", recs['managedBy'] ?? "Patient"),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen())), icon: const Icon(Icons.credit_card, size: 18), label: const Text("Pay Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))),
            const SizedBox(width: 10),
            Expanded(child: _buildChatButtonWithBadge(data['doctorId'] ?? "", data['doctorName'] ?? "Doctor")),
          ]),
        ]),
      ),
    );
  }

  Widget _buildChatButtonWithBadge(String docId, String docName) {
    if (docId.isEmpty) return const SizedBox();
    final String chatId = DirectChatScreen.getChatId(docId, _effectivePatientId);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final chatData = snapshot.data!.data() as Map<String, dynamic>;
          if (chatData['lastSenderId'] == docId && chatData['isRead'] == false) hasUnread = true;
        }
        return Stack(clipBehavior: Clip.none, children: [
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { FirebaseFirestore.instance.collection('chats').doc(chatId).update({'isRead': true}); Navigator.push(context, MaterialPageRoute(builder: (context) => DirectChatScreen(doctorId: docId, patientId: _effectivePatientId, receiverName: docName))); }, icon: const Icon(Icons.chat_bubble_outline, size: 18), label: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: brandBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))),
          if (hasUnread) Positioned(right: 8, top: -5, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 14, minHeight: 14))),
        ]);
      },
    );
  }

  Widget _buildStatusBadge(String status) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: status == 'Approved' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Text(status, style: TextStyle(color: status == 'Approved' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)));
  Widget _buildRecItem(String title, String val) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]));
  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) => TextFormField(controller: ctrl, maxLines: maxLines, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => (v == null || v.isEmpty) ? "Required" : null);
  Widget _buildOriginalStyleField(TextEditingController ctrl, String hint, IconData icon) => TextFormField(controller: ctrl, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))), validator: (v) => (v == null || v.isEmpty) ? "Required" : null);

  void _showScheduleAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          contentPadding: const EdgeInsets.all(25),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Schedule Appointment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Form(key: _apptFormKey, child: Column(children: [
                  _buildDialogTextField(_apptDocNameController, "Doctor Name", Icons.person),
                  const SizedBox(height: 15),
                  _buildDialogTextField(_apptSpecialtyController, "Specialty", Icons.medical_services),
                  const SizedBox(height: 15),
                  _buildDialogPickerField(_apptDateController, "Select Date", Icons.calendar_today, () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() { _apptSelectedDate = picked; _apptDateController.text = DateFormat('yyyy-MM-dd').format(picked); });
                  }),
                  const SizedBox(height: 15),
                  _buildDialogPickerField(_apptTimeController, "Time", Icons.access_time, () async {
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (picked != null) setDialogState(() { _apptSelectedTime = picked; _apptTimeController.text = picked.format(context); });
                  }),
                ])),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSavingAppt ? null : _saveAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: _isSavingAppt 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint, prefixIcon: Icon(icon, color: brandBlue), 
        filled: true, fillColor: brandBlue.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.grey, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: brandBlue, width: 1.0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDialogPickerField(TextEditingController ctrl, String hint, IconData icon, VoidCallback onTap) {
    return TextFormField(
      controller: ctrl, readOnly: true, onTap: onTap,
      decoration: InputDecoration(
        hintText: hint, prefixIcon: Icon(icon, color: brandBlue),
        filled: true, fillColor: brandBlue.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.grey, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: brandBlue, width: 1.0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}
