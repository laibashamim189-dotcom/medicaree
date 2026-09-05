import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'main.dart';
import 'alarm_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (response.payload != null && response.payload!.isNotEmpty) {
    await NotificationService.handleActionLogic(response.payload!, response.actionId);
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

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

      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        await Permission.notification.request();
        bool? canSchedule = await androidPlugin?.canScheduleExactNotifications();
        if (canSchedule == false) {
          await Permission.scheduleExactAlarm.request();
        }

        // Fresh channel with max importance
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'medication_urgent_v9', 
          'Urgent Medication Alarms',
          description: 'Used for precise medical reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
        await androidPlugin?.createNotificationChannel(channel);
      }
      debugPrint("Notification Service READY in $timeZoneName");
    } catch (e) {
      debugPrint("Init Error: $e");
    }
  }

  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_urgent_v9',
      'Urgent Medication Alarms',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
    );

    // Schedule a test for 10 seconds from now to PROVE scheduling works
    final testTime = DateTime.now().add(const Duration(seconds: 10));
    final scheduledTZDate = tz.TZDateTime.from(testTime, tz.local);

    await _notifications.zonedSchedule(
      888,
      'Scheduling Test 🧪',
      'This will fire in 10 seconds if scheduling is working!',
      scheduledTZDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'title': 'Test Logic',
        'type': 'Test',
        'docId': 'test_id',
        'userId': 'test_user',
      }),
    );
    
    debugPrint("Scheduled test notification for: $scheduledTZDate");
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      if (response.actionId == null) {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
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
      final String type = data['type'] ?? 'medication';
      if (docId.isEmpty) return;
      
      String status = "Missed";
      if (actionId == 'action_taken') {
        if (type == 'medication') {
          status = "Taken";
          
          // Stock Refill Logic
          final doc = await FirebaseFirestore.instance.collection('reminders').doc(docId).get();
          if (doc.exists) {
            final docData = doc.data() as Map<String, dynamic>;
            var stockStr = docData['stock']?.toString() ?? "";
            if (stockStr.isNotEmpty) {
              int stock = int.tryParse(stockStr) ?? 0;
              if (stock > 0) {
                stock--;
                await FirebaseFirestore.instance.collection('reminders').doc(docId).update({'stock': stock.toString()});
                
                if (stock < 3) {
                  showImmediateNotification(
                    id: docId.hashCode + 1,
                    title: "Low Stock Alert: ${data['title']}",
                    body: "Only $stock doses left. Please refill your medicine soon!",
                    payload: payload,
                  );
                }
              }
            }
          }
        } else if (type == 'measurement') {
          status = "Measured";
        } else if (type == 'activity') {
          status = "Completed";
        } else if (type == 'appointment') {
          status = "Attended";
        } else {
          status = "Done";
        }
      }

      await FirebaseFirestore.instance.collection('reminders').doc(docId).update({'status': status});
      await FirebaseFirestore.instance.collection('user_history').add({
        'userId': data['userId'] ?? '',
        'reminderId': docId,
        'title': data['title'] ?? '',
        'category': data['type'] ?? '',
        'status': status,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'time': DateFormat.jm().format(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Action Error: $e");
    }
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_urgent_v9',
      'Urgent Medication Alarms',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
    );

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
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
    bool repeats = false,
  }) async {
    try {
      DateTime finalDate = scheduledDate;
      final now = DateTime.now();

      if (finalDate.isBefore(now)) {
        if (repeats) {
          while (finalDate.isBefore(now.add(const Duration(seconds: 5)))) {
            finalDate = finalDate.add(const Duration(days: 1));
          }
        } else {
          finalDate = now.add(const Duration(seconds: 20)); 
        }
      }

      final scheduledTZDate = tz.TZDateTime.from(finalDate, tz.local);
      debugPrint("ALARM SET: '$title' at $scheduledTZDate (Phone Time: $now)");

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
            fullScreenIntent: true,
            ongoing: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeats ? DateTimeComponents.time : null,
        payload: jsonEncode({
          'docId': docId,
          'type': type,
          'title': title,
          'userId': userId ?? '',
        }),
      );
    } catch (e) {
      debugPrint("Scheduling Error: $e");
    }
  }
}
