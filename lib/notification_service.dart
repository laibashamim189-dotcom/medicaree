import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'main.dart';
import 'firebase_options.dart';
import 'alarm_screen.dart';
import 'DirectChatScreen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (response.payload != null && response.payload!.isNotEmpty) {
    await NotificationService.handleActionLogic(response.payload!, response.actionId);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      String timeZoneName = "Asia/Karachi";
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        debugPrint("Timezone detection failed, fallback to $timeZoneName");
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _notifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        try {
          await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
            'chat_messages',
            'Chat Messages',
            description: 'Notifications for new messages',
            importance: Importance.max,
            playSound: true,
            showBadge: true,
          ));
        } catch (e) {
          debugPrint("Chat channel creation failed: $e");
        }

        try {
          await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
            'medication_urgent_v9',
            'Health Reminders',
            description: 'Timely reminders for your health tasks',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ));
        } catch (e) {
          debugPrint("Reminders channel creation failed: $e");
        }
      }

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        String title = message.notification?.title ?? "New Message";
        String body = message.notification?.body ?? "";
        if (message.notification == null && message.data.isNotEmpty) {
          title = message.data['title'] ?? "New Message";
          body = message.data['text'] ?? message.data['body'] ?? "";
        }
        showImmediateNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: jsonEncode(message.data),
          channelId: 'chat_messages',
        );
      });

      updateFCMToken();
    } catch (e) {
      debugPrint("Notification Service Init Error: $e");
    }
  }

  static Future<void> updateFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? token = await _messaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("FCM token update error: $e");
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final Map<String, dynamic> data = jsonDecode(response.payload!);
      if (data['type'] == 'chat') {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => DirectChatScreen(
            doctorId: data['doctorId'] ?? '',
            patientId: data['patientId'] ?? '',
            receiverName: data['senderName'] ?? 'Chat',
          ),
        ));
      } else if (response.actionId == null) {
        data['fullPayload'] = response.payload;
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => AlarmScreen(payload: data)));
      } else {
        handleActionLogic(response.payload!, response.actionId);
      }
    }
  }

  static Future<void> handleActionLogic(String payload, String? actionId, {String? performedBy}) async {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String docId = data['docId'] ?? '';
      final String userId = data['userId'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      final String type = data['type'] ?? 'Reminder';
      final String title = data['title'] ?? 'Reminder';

      if (docId.isEmpty) return;

      String status = (actionId == 'action_missed') ? "Missed" : "Done";
      String? localPerformedBy = performedBy;

      if (actionId == 'action_patient') {
        status = "Done";
        localPerformedBy = "Patient";
      } else if (actionId == 'action_caregiver') {
        status = "Done";
        localPerformedBy = "Caregiver";
      } else if (actionId == 'action_taken') {
        status = "Done";
      }

      final docRef = FirebaseFirestore.instance.collection('reminders').doc(docId);
      await docRef.update({'status': status});

      if (status == "Missed" && localPerformedBy == 'Patient') {
        notifyCaregiverOnDismiss(userId, title, type);
      }

      if (status == "Done" && type.toLowerCase() == 'medication') {
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final reminderData = docSnap.data();
          final String stockStr = reminderData?['stock'] ?? "";
          if (stockStr.isNotEmpty) {
            int currentStock = int.tryParse(stockStr) ?? 0;
            if (currentStock > 0) {
              int newStock = currentStock - 1;
              await docRef.update({'stock': newStock.toString()});
              
              if (newStock <= 3) {
                await showImmediateNotification(
                  id: docId.hashCode,
                  title: "Refill Reminder: $title",
                  body: "Low stock alert! Only $newStock doses left. Please refill your medicine.",
                  channelId: 'medication_urgent_v9',
                );
              }
            }
          }
        }
      }

      String historyStatus = status;
      if (status == "Done") {
        if (type.toLowerCase() == 'medication') historyStatus = 'Taken';
        else if (type.toLowerCase() == 'measurement') historyStatus = 'Measured';
        else if (type.toLowerCase() == 'activity') historyStatus = 'Completed';
        else if (type.toLowerCase() == 'appointment') historyStatus = 'Attended';
      }

      if (localPerformedBy != null) {
        historyStatus = "$historyStatus (by $localPerformedBy)";
      }

      DateTime now = DateTime.now();
      await FirebaseFirestore.instance.collection('user_history').add({
        'userId': userId,
        'title': title,
        'category': type,
        'status': historyStatus,
        'date': DateFormat('yyyy-MM-dd').format(now),
        'time': DateFormat('h:mm a').format(now),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Action logic error: $e");
    }
  }

  static Future<void> notifyCaregiverOnDismiss(String patientId, String taskTitle, String taskType) async {
    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance.collection('users').doc(patientId).get();
      String patientName = patientDoc.exists ? (patientDoc.data() as Map<String, dynamic>)['name'] ?? "Patient" : "Patient";

      QuerySnapshot requestSnap = await FirebaseFirestore.instance
          .collection('caregiver_requests')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in requestSnap.docs) {
        String? caregiverEmail = (doc.data() as Map<String, dynamic>)['caregiverEmail'];
        if (caregiverEmail != null) {
          QuerySnapshot userSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: caregiverEmail)
              .limit(1)
              .get();

          if (userSnap.docs.isNotEmpty) {
            final caregiverData = userSnap.docs.first.data() as Map<String, dynamic>;
            final caregiverId = userSnap.docs.first.id;
            String? fcmToken = caregiverData['fcmToken'];
            
            await FirebaseFirestore.instance.collection('notifications').add({
              'toId': caregiverId, // Target caregiver's UID
              'toToken': fcmToken,
              'title': "Alert: Task Dismissed",
              'body': "$patientName has dismissed their $taskType: $taskTitle",
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'pending'
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error notifying caregiver: $e");
    }
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'chat_messages',
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Notifications',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String docId,
    required String type,
    String? userId,
  }) async {
    try {
      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
      await _notifications.zonedSchedule(
        id.abs() % 1000000,
        title,
        body,
        scheduledTZDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_urgent_v9',
            'Health Reminders',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'docId': docId, 'type': type, 'title': title, 'userId': userId ?? ''}),
      );
    } catch (e) {
      debugPrint("Scheduling error: $e");
    }
  }
}
