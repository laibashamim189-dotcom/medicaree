import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/medical_directory_model.dart';
import '../view_models/medical_directory_view_model.dart';
import '../view_models/direct_chat_view_model.dart';
import 'payment_screen.dart';
import 'direct_chat_screen.dart';

class MedicalDirectoryScreen extends StatefulWidget {
  final String? patientId;
  final bool isReadOnly;

  const MedicalDirectoryScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<MedicalDirectoryScreen> createState() => _MedicalDirectoryScreenState();
}

class _MedicalDirectoryScreenState extends State<MedicalDirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color brandBlue = Color(0xFF1565C0);

  final _doctorFormKey = GlobalKey<FormState>();
  final _caregiverFormKey = GlobalKey<FormState>();
  final _apptFormKey = GlobalKey<FormState>();

  final _docNameController = TextEditingController();
  final _docEmailController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _symptomsController = TextEditingController();

  final _cgNameController = TextEditingController();
  final _cgEmailController = TextEditingController();
  String _relation = 'Relative';

  final _apptDocNameController = TextEditingController();
  final _apptSpecialtyController = TextEditingController();
  final _apptDateController = TextEditingController();
  final _apptTimeController = TextEditingController();

  DateTime? _apptSelectedDate;
  TimeOfDay? _apptSelectedTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
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

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicalDirectoryViewModel()..init(widget.patientId),
      child: Consumer<MedicalDirectoryViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: brandBlue,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("Medical Directory", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                _buildDoctorTab(viewModel),
                _buildCaregiverTab(viewModel),
                _buildAppointmentsTab(viewModel),
              ],
            ),
            floatingActionButton: (_tabController.index == 2 && !widget.isReadOnly)
                ? FloatingActionButton(
                    onPressed: () => _showScheduleAppointmentDialog(viewModel),
                    backgroundColor: brandBlue,
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildDoctorTab(MedicalDirectoryViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isReadOnly) ...[
            const Text("Request Doctor Connection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Form(
              key: _doctorFormKey,
              child: Column(
                children: [
                  _buildTextField(_docNameController, "Doctor's Name", Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_docEmailController, "Doctor's Email", Icons.email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _buildTextField(_specialtyController, "Specialty", Icons.medical_services),
                  const SizedBox(height: 15),
                  _buildTextField(_symptomsController, "Reason/Symptoms", Icons.assignment, maxLines: 2),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading ? null : () async {
                        if (_doctorFormKey.currentState!.validate()) {
                          bool success = await viewModel.sendDoctorRequest(
                            doctorName: _docNameController.text,
                            doctorEmail: _docEmailController.text,
                            specialty: _specialtyController.text,
                            symptoms: _symptomsController.text,
                          );
                          if (success) {
                            _showSnackBar("Doctor request sent!");
                            _docNameController.clear();
                            _docEmailController.clear();
                            _specialtyController.clear();
                            _symptomsController.clear();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            const Divider(),
          ],
          const SizedBox(height: 20),
          const Text("Sent Requests & Responses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildList(viewModel.getDoctorRequestsStream(), viewModel, 'doctor_requests'),
        ],
      ),
    );
  }

  Widget _buildCaregiverTab(MedicalDirectoryViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isReadOnly) ...[
            const Text("Request Caregiver Connection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Form(
              key: _caregiverFormKey,
              child: Column(
                children: [
                  _buildTextField(_cgNameController, "Caregiver Full Name", Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_cgEmailController, "Caregiver Email", Icons.email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _relation,
                    decoration: InputDecoration(
                      labelText: "Relationship",
                      prefixIcon: const Icon(Icons.people, color: brandBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                    items: ['Relative', 'Professional Nurse', 'Friend', 'Other']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => _relation = v!),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading ? null : () async {
                        if (_caregiverFormKey.currentState!.validate()) {
                          bool success = await viewModel.sendCaregiverRequest(
                            cgName: _cgNameController.text,
                            cgEmail: _cgEmailController.text,
                            relation: _relation,
                          );
                          if (success) {
                            _showSnackBar("Caregiver request sent!");
                            _cgNameController.clear();
                            _cgEmailController.clear();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            const Divider(),
          ],
          const SizedBox(height: 20),
          const Text("Caregiver Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildList(viewModel.getCaregiverRequestsStream(), viewModel, 'caregiver_requests'),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab(MedicalDirectoryViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildList(viewModel.getAppointmentsStream(), viewModel, 'reminders', isAppointment: true),
    );
  }

  Widget _buildList(Stream<List<MedicalItemModel>> stream, MedicalDirectoryViewModel viewModel, String collection, {bool isAppointment = false}) {
    return StreamBuilder<List<MedicalItemModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("No records found", style: TextStyle(color: Colors.grey))),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final status = item.status;

            if (isAppointment) {
              return _buildAppointmentListItem(item, viewModel, collection);
            }
            
            if (collection == 'caregiver_requests') {
              return _buildCaregiverListItem(item, viewModel, collection);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Slidable(
                key: Key(item.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (context) => viewModel.deleteItem(collection, item.id),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.grey,
                      icon: Icons.delete_outline,
                    ),
                  ],
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.grey[50],
                  elevation: 0.5,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(item.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        trailing: _buildStatusBadge(status),
                      ),
                      if (item.type == 'doctor_request' && status.toLowerCase() == 'approved' && item.recommendations != null)
                        _buildRecommendationsBox(item, viewModel),
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

  Widget _buildCaregiverListItem(MedicalItemModel item, MedicalDirectoryViewModel viewModel, String collection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(item.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) => viewModel.deleteItem(collection, item.id),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.grey,
              icon: Icons.delete_outline,
            ),
          ],
        ),
        child: Card(
          elevation: 0.5,
          margin: EdgeInsets.zero,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(item.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(item.status),
                  ],
                ),
                if (item.status.toLowerCase() == 'accepted') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildChatButtonExactStyle(item, viewModel),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatButtonExactStyle(MedicalItemModel item, MedicalDirectoryViewModel viewModel) {
    final String targetId = (item.type == 'doctor_request' ? item.doctorId : item.caregiverId) ?? '';
    if (targetId.isEmpty) return const SizedBox();
    final String chatId = DirectChatScreen.getChatId(targetId, viewModel.effectivePatientId);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final chatData = snapshot.data!.data() as Map<String, dynamic>;
          if (chatData['lastSenderId'] == targetId && chatData['isRead'] == false) {
            hasUnread = true;
          }
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 36,
              width: 105,
              child: ElevatedButton.icon(
                onPressed: () {
                  FirebaseFirestore.instance.collection('chats').doc(chatId).update({'isRead': true});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => DirectChatViewModel(),
                        child: DirectChatScreen(
                          doctorId: targetId,
                          patientId: viewModel.effectivePatientId,
                          receiverName: item.title,
                          isReadOnly: widget.isReadOnly,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                label: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                right: 4,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentListItem(MedicalItemModel item, MedicalDirectoryViewModel viewModel, String collection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(item.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) => viewModel.deleteItem(collection, item.id),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.grey,
              icon: Icons.delete_outline,
            ),
          ],
        ),
        child: Card(
          elevation: 0.5,
          margin: EdgeInsets.zero,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: brandBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today_outlined, color: brandBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      const SizedBox(height: 2),
                      Text("${item.date} at ${item.time}", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                if (!widget.isReadOnly) ...[
                  const Icon(Icons.notifications_active, color: brandBlue, size: 20),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showEditAppointmentDialog(item, viewModel),
                    child: const Icon(Icons.edit, color: brandBlue, size: 20),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsBox(MedicalItemModel item, MedicalDirectoryViewModel viewModel) {
    final recs = item.recommendations!;
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 5),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE1EBF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: brandBlue, size: 20),
                const SizedBox(width: 10),
                const Text(
                  "Doctor's Recommendations:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue, fontSize: 16),
                )
              ],
            ),
            const Divider(height: 30),
            _buildRecItem("Medications", recs['meds'] ?? "N/A"),
            _buildRecItem("Measurements", recs['measurements'] ?? "N/A"),
            _buildRecItem("Activities/Diet", recs['activities'] ?? "N/A"),
            _buildRecItem("Managed By", recs['managedBy'] ?? "Patient"),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentScreen(initialDoctorId: item.doctorId ?? '')),
                      ),
                      icon: const Icon(Icons.credit_card, size: 18),
                      label: const Text("Pay Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChatButtonForDoctor(item, viewModel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButtonForDoctor(MedicalItemModel item, MedicalDirectoryViewModel viewModel) {
    final String targetId = item.doctorId ?? '';
    if (targetId.isEmpty) return const SizedBox();
    final String chatId = DirectChatScreen.getChatId(targetId, viewModel.effectivePatientId);

    bool isCaregiver = (viewModel.currentUserId != viewModel.effectivePatientId);
    bool chatIsReadOnly = widget.isReadOnly;
    if (isCaregiver && (item.recommendations?['managedBy'] ?? '').toString().toLowerCase() == 'patient') {
      chatIsReadOnly = true;
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final chatData = snapshot.data!.data() as Map<String, dynamic>;
          if (chatData['lastSenderId'] == targetId && chatData['isRead'] == false) hasUnread = true;
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 40,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  FirebaseFirestore.instance.collection('chats').doc(chatId).update({'isRead': true});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => DirectChatViewModel(),
                        child: DirectChatScreen(
                          doctorId: targetId,
                          patientId: viewModel.effectivePatientId,
                          receiverName: item.title,
                          isReadOnly: chatIsReadOnly,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                label: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                right: 12,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecItem(String title, String val) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          ],
        ),
      );

  Widget _buildStatusBadge(String status) {
    String lower = status.toLowerCase();
    bool isOk = lower == 'approved' || lower == 'accepted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOk ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: isOk ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue, size: 22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  void _showScheduleAppointmentDialog(MedicalDirectoryViewModel viewModel) {
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
                Form(
                  key: _apptFormKey,
                  child: Column(
                    children: [
                      _buildDialogTextField(_apptDocNameController, "Doctor Name", Icons.person),
                      const SizedBox(height: 15),
                      _buildDialogTextField(_apptSpecialtyController, "Specialty", Icons.medical_services),
                      const SizedBox(height: 15),
                      _buildDialogPickerField(_apptDateController, "Select Date", Icons.calendar_today, () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _apptSelectedDate = picked;
                            _apptDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      }),
                      const SizedBox(height: 15),
                      _buildDialogPickerField(_apptTimeController, "Time", Icons.access_time, () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _apptSelectedTime = picked;
                            _apptTimeController.text = picked.format(context);
                          });
                        }
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading ? null : () async {
                          if (_apptFormKey.currentState!.validate()) {
                            bool success = await viewModel.saveAppointment(
                              doctorName: _apptDocNameController.text,
                              specialty: _apptSpecialtyController.text,
                              dateText: _apptDateController.text,
                              timeText: _apptTimeController.text,
                              selectedDate: _apptSelectedDate,
                              selectedTime: _apptSelectedTime,
                            );
                            if (success) {
                              Navigator.pop(context);
                              _showSnackBar("Appointment scheduled successfully!");
                              _apptDocNameController.clear();
                              _apptSpecialtyController.clear();
                              _apptTimeController.clear();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: viewModel.isLoading
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

  void _showEditAppointmentDialog(MedicalItemModel item, MedicalDirectoryViewModel viewModel) {
    _apptDocNameController.text = item.title;
    _apptSpecialtyController.text = item.subtitle;
    _apptDateController.text = item.date;
    _apptTimeController.text = item.time;
    
    try {
      _apptSelectedDate = DateFormat('yyyy-MM-dd').parse(item.date);
    } catch (e) {
      _apptSelectedDate = DateTime.now();
    }

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
                const Text("Edit Appointment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Form(
                  key: _apptFormKey,
                  child: Column(
                    children: [
                      _buildDialogTextField(_apptDocNameController, "Doctor Name", Icons.person),
                      const SizedBox(height: 15),
                      _buildDialogTextField(_apptSpecialtyController, "Specialty", Icons.medical_services),
                      const SizedBox(height: 15),
                      _buildDialogPickerField(_apptDateController, "Select Date", Icons.calendar_today, () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _apptSelectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _apptSelectedDate = picked;
                            _apptDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      }),
                      const SizedBox(height: 15),
                      _buildDialogPickerField(_apptTimeController, "Time", Icons.access_time, () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _apptSelectedTime = picked;
                            _apptTimeController.text = picked.format(context);
                          });
                        }
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_apptFormKey.currentState!.validate()) {
                            await FirebaseFirestore.instance.collection('reminders').doc(item.id).update({
                              'doctorName': _apptDocNameController.text,
                              'specialty': _apptSpecialtyController.text,
                              'date': _apptDateController.text,
                              'time': _apptTimeController.text,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showSnackBar("Appointment updated successfully!");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        filled: true,
        fillColor: brandBlue.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.grey, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: brandBlue, width: 1.0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDialogPickerField(TextEditingController ctrl, String hint, IconData icon, VoidCallback onTap) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: brandBlue),
        filled: true,
        fillColor: brandBlue.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.grey, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: brandBlue, width: 1.0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}
