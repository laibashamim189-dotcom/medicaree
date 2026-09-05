import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'splash_screen.dart';
import 'doctor_dashboard.dart';
import 'caregiver_dashboard.dart';
import 'patient_dashboard.dart';
import 'notification_service.dart';
import 'login_screen.dart';
import 'alarm_screen.dart';

// Global key to handle navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Notification Init
    await NotificationService.init();

    // CRITICAL: Request all necessary permissions on start
    await _requestRequiredPermissions();
    
  } catch (e) {
    debugPrint("Initialization error: $e");
  }

  runApp(const MedicareApp());
}

Future<void> _requestRequiredPermissions() async {
  // 1. Notification Permission (Android 13+)
  await Permission.notification.request();

  // 2. Exact Alarm Permission (Android 13+)
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }

  // 3. Ignore Battery Optimizations
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}

class MedicareApp extends StatelessWidget {
  const MedicareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Set the global navigator key
      debugShowCheckedModeBanner: false,
      title: 'Medicare: Smart Health Reminder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class RoleWrapper extends StatelessWidget {
  final String role;
  const RoleWrapper({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'Doctor':
        return const DoctorDashboard();
      case 'Caregiver':
        return const CaregiverDashboard();
      case 'Patient':
        return const PatientDashboard(); 
      default:
        return const LoginScreen();
    }
  }
}
