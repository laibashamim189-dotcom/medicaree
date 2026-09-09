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
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'main.dart';
import 'alarm_screen.dart';
import 'DirectChatScreen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (response.payload != null && response.payload!.isNotEmpty) {
    await NotificationService.handleActionLogic(response.payload!, response.actionId);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Got a message whilst in the foreground!");
        debugPrint("Message data: ${message.data}");

        String title = message.notification?.title ?? "New Message";
        String body = message.notification?.body ?? "";
        
        if (message.notification == null && message.data.isNotEmpty) {
          title = message.data['title'] ?? "New Message";
          body = message.data['text'] ?? message.data['body'] ?? "";
        }

        String channelId = 'chat_messages'; // Force chat channel for testing
        
        showImmediateNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: jsonEncode(message.data),
          channelId: channelId,
        );
      });

      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          description: 'Notifications for new messages',
          importance: Importance.max, 
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlugin?.createNotificationChannel(chatChannel);
      }
      
      updateFCMToken();
    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }
  }

  static Future<void> updateFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? token = await _messaging.getToken();
        debugPrint("FCM Token: $token"); // Debugging token
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
          debugPrint("Token updated in Firestore for user: ${user.uid}");
        }
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final Map<String, dynamic> data = jsonDecode(response.payload!);
      if (data['type'] == 'chat') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DirectChatScreen(
              doctorId: data['doctorId'] ?? '',
              patientId: data['patientId'] ?? '',
              receiverName: data['senderName'] ?? 'Chat',
            ),
          ),
        );
        return;
      }
      if (response.actionId == null) {
        data['fullPayload'] = response.payload;
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => AlarmScreen(payload: data))
        );
      } else {
        handleActionLogic(response.payload!, response.actionId);
      }
    }
  }

  static Future<void> handleActionLogic(String payload, String? actionId) async {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String docId = data['docId'] ?? '';
      if (docId.isEmpty) return;
      String status = (actionId == 'action_taken') ? "Done" : "Missed";
      await FirebaseFirestore.instance.collection('reminders').doc(docId).update({'status': status});
    } catch (e) {
      debugPrint("Action Logic Error: $e");
    }
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'chat_messages',
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      playSound: true,
      ticker: 'ticker',
    );
    await _notifications.show(id, title, body, NotificationDetails(android: androidDetails), payload: payload);
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
            'Urgent Medication Alarms',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'docId': docId, 'type': type, 'title': title, 'userId': userId ?? ''}),
      );
    } catch (e) {
      debugPrint("Scheduling Error: $e");
    }
  }
}
