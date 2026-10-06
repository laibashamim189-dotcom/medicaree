import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class DirectChatViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? doctorId;
  String? patientId;
  String? receiverName;
  bool isReadOnly = false;

  String myRoleTag = '';
  String myUserName = 'User';
  String currentUserRole = '';
  bool isDoctorPatientChat = false;
  String caregiverId = '';

  int activeTab = 0;
  int doctorPrivateTarget = 0;

  bool hasAcceptedCaregiver = false;
  bool isManagedByBoth = false;
  bool isLoadingStatus = true;

  final Set<String> selectedMessageIds = {};

  User? get currentUser => _auth.currentUser;
  String get currentUserId => currentUser?.uid ?? '';

  bool get showTabs => isDoctorPatientChat && hasAcceptedCaregiver && isManagedByBoth;

  void init({
    required String docId,
    required String patId,
    required String recName,
    required bool readOnly,
  }) {
    doctorId = docId;
    patientId = patId;
    receiverName = recName;
    isReadOnly = readOnly;

    markAsRead();
    clearRelevantNotifications();
    initChatLogic();
  }

  static String getChatId(String id1, String id2) {
    List<String> ids = [id1.trim().toLowerCase(), id2.trim().toLowerCase()];
    ids.sort();
    return ids.join('_');
  }

  String get currentChatId => getChatId(doctorId ?? '', patientId ?? '');

  Future<void> initChatLogic() async {
    isLoadingStatus = true;
    notifyListeners();

    await _fetchCurrentUserDetails();
    await _checkIfDoctor();
    await _fetchCaregiverAndRecommendation();

    isLoadingStatus = false;
    notifyListeners();
  }

  Future<void> _fetchCurrentUserDetails() async {
    if (currentUser == null) return;
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        myUserName = userDoc.get('name') ?? 'User';
        currentUserRole = (userDoc.get('role') ?? '').toString().trim();
        if (currentUserRole.toLowerCase() == 'caregiver') {
          myRoleTag = ' [Caregiver]';
        } else if (currentUserRole.toLowerCase() == 'patient') {
          myRoleTag = ' [Patient]';
        }
      }
    } catch (e) {
      debugPrint("User details fetch error: $e");
    }
  }

  Future<void> _checkIfDoctor() async {
    if (doctorId == null) return;
    try {
      DocumentSnapshot docUserDoc = await _firestore.collection('users').doc(doctorId!.trim()).get();
      if (docUserDoc.exists) {
        String role = (docUserDoc.get('role') ?? '').toString().toLowerCase();
        isDoctorPatientChat = (role == 'doctor');
      }
    } catch (e) {
      debugPrint("Doctor check error: $e");
    }
  }

  Future<void> _fetchCaregiverAndRecommendation() async {
    if (patientId == null) return;
    try {
      var cgSnap = await _firestore
          .collection('caregiver_requests')
          .where('patientId', isEqualTo: patientId!.trim())
          .get();

      bool cgFound = false;
      for (var doc in cgSnap.docs) {
        String status = (doc.data()['status'] ?? '').toString().toLowerCase();
        if (status == 'accepted') {
          cgFound = true;
          caregiverId = (doc.data()['caregiverId'] ?? '').toString().trim();
          break;
        }
      }

      var docReqSnap = await _firestore
          .collection('doctor_requests')
          .where('patientId', isEqualTo: patientId!.trim())
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
        if (latestDoc['doctorId'].toString().trim() == doctorId!.trim() || latestDoc['doctorName'] == receiverName) {
          var recs = latestDoc['recommendations'] as Map<String, dynamic>?;
          if (recs != null) {
            String mBy = (recs['managedBy'] ?? '').toString().toLowerCase();
            if (mBy == 'both') managedByBoth = true;
          }
        }
      }

      hasAcceptedCaregiver = cgFound;
      isManagedByBoth = managedByBoth;
    } catch (e) {
      debugPrint("Status fetch error: $e");
    }
  }

  void setActiveTab(int index) {
    activeTab = index;
    notifyListeners();
  }

  void setDoctorPrivateTarget(int target) {
    doctorPrivateTarget = target;
    notifyListeners();
  }

  void markAsRead() {
    if (currentChatId.isEmpty) return;
    _firestore.collection('chats').doc(currentChatId).update({'isRead': true}).catchError((e) => null);
  }

  void clearRelevantNotifications() {
    if (currentUser == null) return;

    _firestore
        .collection('notifications')
        .where('toId', isEqualTo: currentUser!.uid)
        .where('chatId', isEqualTo: currentChatId)
        .where('status', isEqualTo: 'pending')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'status': 'delivered'});
      }
    }).catchError((e) => debugPrint("Error clearing notifications: $e"));
  }

  Stream<List<ChatMessageModel>> getMessagesStream() {
    return _firestore
        .collection('chats')
        .doc(currentChatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .where((msg) {
        if (msg.deletedFor.contains(currentUserId)) return false;

        bool msgIsPrivate = msg.isPrivate;
        if (!showTabs) return !msgIsPrivate;
        if (activeTab == 0) return !msgIsPrivate;
        if (!msgIsPrivate) return false;

        String pType = msg.privateType ?? '';
        String roleLower = currentUserRole.toLowerCase();

        if (roleLower == 'patient') return pType == 'doctor_patient';
        if (roleLower == 'caregiver') return pType == 'doctor_caregiver';
        if (roleLower == 'doctor') {
          return (doctorPrivateTarget == 0) ? (pType == 'doctor_patient') : (pType == 'doctor_caregiver');
        }
        return true;
      }).toList();
    });
  }

  Future<void> sendMessage(String text) async {
    if (currentUser == null || isReadOnly || text.trim().isEmpty) return;

    final String myId = currentUserId;
    final String cleanText = text.trim();

    bool isPrivate = (showTabs && activeTab == 1);
    String privateTargetId = '';
    String pType = '';

    if (isPrivate) {
      String roleLower = currentUserRole.toLowerCase();
      if (roleLower == 'patient') {
        privateTargetId = doctorId!.trim();
        pType = 'doctor_patient';
      } else if (roleLower == 'caregiver') {
        privateTargetId = doctorId!.trim();
        pType = 'doctor_caregiver';
      } else if (roleLower == 'doctor') {
        if (doctorPrivateTarget == 0) {
          privateTargetId = patientId!.trim();
          pType = 'doctor_patient';
        } else {
          privateTargetId = caregiverId;
          pType = 'doctor_caregiver';
        }
      }
    }

    Map<String, dynamic> messageData = {
      'senderId': myId,
      'senderName': myUserName,
      'timestamp': FieldValue.serverTimestamp(),
      'isPrivate': isPrivate,
      'text': (showTabs && activeTab == 0 && myRoleTag.isNotEmpty) ? "$cleanText$myRoleTag" : cleanText,
      'receiverId': isPrivate ? privateTargetId : (myId == doctorId!.trim() ? patientId!.trim() : doctorId!.trim()),
    };
    if (isPrivate) messageData['privateType'] = pType;

    await _firestore.collection('chats').doc(currentChatId).collection('messages').add(messageData);

    Set<String> recipientIds = {};
    if (isPrivate) {
      if (privateTargetId.isNotEmpty) recipientIds.add(privateTargetId.trim());
    } else {
      recipientIds.add(doctorId!.trim());
      recipientIds.add(patientId!.trim());
      if (caregiverId.isNotEmpty) recipientIds.add(caregiverId.trim());
    }

    recipientIds.removeWhere((id) => id.isEmpty || id.trim() == myId);

    for (String rid in recipientIds) {
      _firestore.collection('notifications').add({
        'toId': rid.trim(),
        'fromId': myId,
        'senderId': myId,
        'fromName': myUserName,
        'senderName': myUserName,
        'title': "New Message from $myUserName",
        'body': cleanText,
        'type': 'chat',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'chatId': currentChatId,
        'doctorId': doctorId!.trim(),
        'patientId': patientId!.trim(),
      });
    }

    await _firestore.collection('chats').doc(currentChatId).set({
      'lastMessage': messageData['text'],
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSenderId': myId,
      'isRead': false,
      'users': [doctorId!.trim(), patientId!.trim()],
    }, SetOptions(merge: true));
  }

  void toggleMessageSelection(String msgId) {
    if (selectedMessageIds.contains(msgId)) {
      selectedMessageIds.remove(msgId);
    } else {
      selectedMessageIds.add(msgId);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedMessageIds.clear();
    notifyListeners();
  }

  Future<void> deleteForEveryone() async {
    if (selectedMessageIds.isEmpty) return;
    final batch = _firestore.batch();
    for (String msgId in selectedMessageIds) {
      batch.delete(_firestore.collection('chats').doc(currentChatId).collection('messages').doc(msgId));
    }
    await batch.commit();
    clearSelection();
  }

  Future<void> deleteForMe() async {
    if (currentUser == null || selectedMessageIds.isEmpty) return;
    final batch = _firestore.batch();
    for (String msgId in selectedMessageIds) {
      batch.update(
        _firestore.collection('chats').doc(currentChatId).collection('messages').doc(msgId),
        {'deletedFor': FieldValue.arrayUnion([currentUserId])},
      );
    }
    await batch.commit();
    clearSelection();
  }
}