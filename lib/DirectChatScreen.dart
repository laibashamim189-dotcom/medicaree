import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DirectChatScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;
  final String receiverName;
  final bool isReadOnly; 

  const DirectChatScreen({
    super.key,
    required this.doctorId,
    required this.patientId,
    required this.receiverName,
    this.isReadOnly = false,
  });

  static String getChatId(String id1, String id2) {
    List<String> ids = [id1.trim(), id2.trim()];
    ids.sort();
    return ids.join('_');
  }

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final Set<String> _selectedMessageIds = {};
  String _myRoleTag = '';
  String _myUserName = 'User';
  
  int _activeTab = 0; 
  String _currentUserRole = '';
  bool _isDoctorPatientChat = false;
  String _caregiverId = '';
  int _doctorPrivateTarget = 0; 
  
  bool _hasAcceptedCaregiver = false; 
  bool _isManagedByBoth = false; 
  bool _isLoadingStatus = true;

  static const Color brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _initChatLogic();
  }

  Future<void> _initChatLogic() async {
    await _fetchCurrentUserDetails();
    await _checkIfDoctor();
    await _fetchCaregiverAndRecommendation();
    if (mounted) setState(() { _isLoadingStatus = false; });
  }

  Future<void> _fetchCurrentUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _myUserName = userDoc.get('name') ?? 'User';
        _currentUserRole = userDoc.get('role') ?? '';
        if (_currentUserRole == 'Caregiver') _myRoleTag = ' [Caregiver]';
        else if (_currentUserRole == 'Patient') _myRoleTag = ' [Patient]';
      }
    } catch (e) { debugPrint("User details fetch error: $e"); }
  }

  Future<void> _checkIfDoctor() async {
    try {
      DocumentSnapshot docUserDoc = await FirebaseFirestore.instance.collection('users').doc(widget.doctorId.trim()).get();
      if (docUserDoc.exists) {
        String role = (docUserDoc.get('role') ?? '').toString().toLowerCase();
        _isDoctorPatientChat = (role == 'doctor');
      }
    } catch (e) { debugPrint("Doctor check error: $e"); }
  }

  Future<void> _fetchCaregiverAndRecommendation() async {
    try {
      var cgSnap = await FirebaseFirestore.instance
          .collection('caregiver_requests')
          .where('patientId', isEqualTo: widget.patientId.trim())
          .get();
          
      bool cgFound = false;
      for (var doc in cgSnap.docs) {
        String status = (doc.data()['status'] ?? '').toString().toLowerCase();
        if (status == 'accepted') {
          cgFound = true;
          _caregiverId = (doc.data()['caregiverId'] ?? '').toString().trim();
          break;
        }
      }

      var docReqSnap = await FirebaseFirestore.instance
          .collection('doctor_requests')
          .where('patientId', isEqualTo: widget.patientId.trim())
          .where('status', isEqualTo: 'Approved')
          .get();

      bool managedByBoth = false;
      if (docReqSnap.docs.isNotEmpty) {
        var docs = docReqSnap.docs.toList();
        docs.sort((a, b) {
          var t1 = a['timestamp'] as Timestamp?;
          var t2 = b['timestamp'] as Timestamp?;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });
        
        var latestDoc = docs.first.data();
        if (latestDoc['doctorId'].toString().trim() == widget.doctorId.trim() || latestDoc['doctorName'] == widget.receiverName) {
          var recs = latestDoc['recommendations'] as Map<String, dynamic>?;
          if (recs != null) {
            String mBy = (recs['managedBy'] ?? '').toString().toLowerCase();
            if (mBy == 'both') managedByBoth = true;
          }
        }
      }

      if (mounted) {
        setState(() {
          _hasAcceptedCaregiver = cgFound;
          _isManagedByBoth = managedByBoth;
        });
      }
    } catch (e) { debugPrint("Status fetch error: $e"); }
  }

  void _markAsRead() {
    final String chatId = DirectChatScreen.getChatId(widget.doctorId, widget.patientId);
    FirebaseFirestore.instance.collection('chats').doc(chatId).update({'isRead': true}).catchError((e) => null);
  }

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.isReadOnly) return;

    final String myId = user.uid.trim();
    final String myIdLower = myId.toLowerCase();
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final String chatId = DirectChatScreen.getChatId(widget.doctorId, widget.patientId);
    bool showTabs = _isDoctorPatientChat && _hasAcceptedCaregiver && _isManagedByBoth;
    bool isPrivate = (showTabs && _activeTab == 1);
    
    String privateTargetId = '';
    String pType = '';
    
    if (isPrivate) {
      if (_currentUserRole == 'Patient') {
        privateTargetId = widget.doctorId.trim();
        pType = 'doctor_patient';
      } else if (_currentUserRole == 'Caregiver') {
        privateTargetId = widget.doctorId.trim();
        pType = 'doctor_caregiver';
      } else if (_currentUserRole == 'Doctor') {
        if (_doctorPrivateTarget == 0) {
          privateTargetId = widget.patientId.trim();
          pType = 'doctor_patient';
        } else {
          privateTargetId = _caregiverId;
          pType = 'doctor_caregiver';
        }
      }
    }

    Map<String, dynamic> messageData = {
      'senderId': myId,
      'timestamp': FieldValue.serverTimestamp(),
      'isPrivate': isPrivate,
      'text': (showTabs && _activeTab == 0 && _myRoleTag.isNotEmpty) ? "$text$_myRoleTag" : text,
      'receiverId': isPrivate ? privateTargetId : (myIdLower == widget.doctorId.trim().toLowerCase() ? widget.patientId.trim() : widget.doctorId.trim()),
    };
    if (isPrivate) messageData['privateType'] = pType;

    // Building the notification set - ADD EVERYONE THEN REMOVE ME
    Set<String> notifyIds = {};
    if (isPrivate) {
      if (privateTargetId.isNotEmpty) notifyIds.add(privateTargetId.trim());
    } else {
      // In group or standard mode, potentially everyone could be a receiver
      notifyIds.add(widget.doctorId.trim());
      notifyIds.add(widget.patientId.trim());
      if (_caregiverId.isNotEmpty) notifyIds.add(_caregiverId.trim());
    }

    // MANDATORY SENDER EXCLUSION: Robust removal of the person sending this message
    notifyIds.removeWhere((id) => 
      id.isEmpty || 
      id.toLowerCase().trim() == myIdLower
    );

    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add(messageData);
    
    for (String rid in notifyIds) {
      if (rid.toLowerCase().trim() == myIdLower) continue;
      
      FirebaseFirestore.instance.collection('notifications').add({
        'toId': rid,
        'fromId': myId,
        'fromName': _myUserName,
        'title': "New Message from $_myUserName",
        'body': text,
        'type': 'chat',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'doctorId': widget.doctorId.trim(),
        'patientId': widget.patientId.trim(),
      });
    }

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': messageData['text'],
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSenderId': myId,
      'isRead': false,
      'users': [widget.doctorId.trim(), widget.patientId.trim()],
    }, SetOptions(merge: true));
  }

  void _performDelete() async {
    final String chatId = DirectChatScreen.getChatId(widget.doctorId, widget.patientId);
    if (_selectedMessageIds.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (String msgId in _selectedMessageIds) {
      batch.delete(FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc(msgId));
    }
    await batch.commit();
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String myIdLower = (user?.uid ?? "").toLowerCase().trim();
    bool showTabs = _isDoctorPatientChat && _hasAcceptedCaregiver && _isManagedByBoth;

    return Scaffold(
      appBar: AppBar(
        leading: _selectedMessageIds.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedMessageIds.clear()),
              )
            : null,
        title: _selectedMessageIds.isEmpty
            ? Text(widget.receiverName)
            : Text("${_selectedMessageIds.length}"),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedMessageIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _performDelete,
            ),
        ],
      ),
      body: _isLoadingStatus 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              if (showTabs) _buildToggleBar(),
              if (showTabs && _activeTab == 1 && _currentUserRole == 'Doctor') 
                _buildDoctorTargetSelector(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(DirectChatScreen.getChatId(widget.doctorId, widget.patientId))
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No messages yet."));

                    final allDocs = snapshot.data!.docs;
                    final messages = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      bool msgIsPrivate = data['isPrivate'] ?? false;
                      if (!showTabs) return !msgIsPrivate;
                      if (_activeTab == 0) return !msgIsPrivate;
                      if (!msgIsPrivate) return false;
                      String pType = data['privateType'] ?? '';
                      if (_currentUserRole == 'Patient') return pType == 'doctor_patient';
                      if (_currentUserRole == 'Caregiver') return pType == 'doctor_caregiver';
                      if (_currentUserRole == 'Doctor') {
                        return (_doctorPrivateTarget == 0) ? (pType == 'doctor_patient') : (pType == 'doctor_caregiver');
                      }
                      return true;
                    }).toList();

                    if (messages.isEmpty) return const Center(child: Text("No messages here."));

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data() as Map<String, dynamic>;
                        final bool isMe = data['senderId'].toString().trim().toLowerCase() == myIdLower;
                        final String msgId = messages[index].id;
                        final bool isSelected = _selectedMessageIds.contains(msgId);
                        String rawText = data['text'] ?? "";
                        String tagLabel = "";
                        String displayText = rawText;

                        if (rawText.endsWith(" [Caregiver]")) {
                          tagLabel = "Caregiver";
                          displayText = rawText.replaceAll(" [Caregiver]", "");
                        } else if (rawText.endsWith(" [Patient]")) {
                          tagLabel = "Patient";
                          displayText = rawText.replaceAll(" [Patient]", "");
                        }

                        return GestureDetector(
                          onLongPress: () => setState(() => _selectedMessageIds.add(msgId)),
                          onTap: () {
                            if (_selectedMessageIds.isNotEmpty) {
                              setState(() => isSelected ? _selectedMessageIds.remove(msgId) : _selectedMessageIds.add(msgId));
                            }
                          },
                          child: Container(
                            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(color: isMe ? brandBlue : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (tagLabel.isNotEmpty && showTabs && _activeTab == 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(tagLabel, style: TextStyle(color: isMe ? Colors.lightGreenAccent[400] : Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    Text(displayText, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (!widget.isReadOnly) _buildInputArea(showTabs)
              else Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.grey[100],
                child: const Text(
                  "Read-only access. Management belongs to patient.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _toggleTab(0, "Group Chat"),
          _toggleTab(1, "Private Chat"),
        ],
      ),
    );
  }

  Widget _toggleTab(int index, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _activeTab == index ? brandBlue : Colors.transparent, width: 3))),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _activeTab == index ? brandBlue : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildDoctorTargetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("With Patient"),
            selected: _doctorPrivateTarget == 0,
            onSelected: (selected) {
              if (selected) setState(() => _doctorPrivateTarget = 0);
            },
            selectedColor: brandBlue.withOpacity(0.2),
            checkmarkColor: brandBlue,
          ),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text("With Caregiver"),
            selected: _doctorPrivateTarget == 1,
            onSelected: (selected) {
              if (selected) setState(() => _doctorPrivateTarget = 1);
            },
            selectedColor: brandBlue.withOpacity(0.2),
            checkmarkColor: brandBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool showTabs) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _messageController, decoration: InputDecoration(hintText: (showTabs && _activeTab == 0) ? "Type a group message..." : "Type a message...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)), filled: true, fillColor: Colors.grey[100]))),
          IconButton(icon: const Icon(Icons.send, color: brandBlue), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
