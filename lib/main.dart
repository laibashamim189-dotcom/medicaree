import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'doctor_dashboard.dart';
import 'doctor_search_screen.dart';
import 'caregiver_dashboard.dart';
import 'patient_dashboard.dart';

void main() async {
  // Ensure Flutter is initialized before any plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const MedicareApp());
}

class MedicareApp extends StatelessWidget {
  const MedicareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      // App starts with SplashScreen
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
        // Modified: Patients now see the Doctor Search Screen first
        return const DoctorSearchScreen();
      default:
        return const DoctorSearchScreen();
    }
  }
}
