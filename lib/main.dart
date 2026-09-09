import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'doctor_dashboard.dart';
import 'caregiver_dashboard.dart';
import 'patient_dashboard.dart';
import 'pharmacy_dashboard.dart';
import 'notification_service.dart';
import 'login_screen.dart';
import 'doctor_license_upload_screen.dart';
import 'pharmacist_license_upload_screen.dart';
import 'nurse_license_upload_screen.dart';

// Global key to handle navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
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
  await Permission.notification.request();

  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }

  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}

class MedicareApp extends StatelessWidget {
  const MedicareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    // Verification check for Doctor, Pharmacist, or Nurse (Caregiver)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String status = data['licenseStatus'] ?? 'NOT_SUBMITTED';
        final String? caregiverType = data['caregiverType'];

        // If it's a Nurse, they must be verified
        if (role == 'Caregiver' && caregiverType == 'Nurse') {
          if (status == 'APPROVED') {
            return const CaregiverDashboard();
          } else {
            return const NurseLicenseUploadScreen();
          }
        }

        // Logic for Doctor and Pharmacist
        if (role == 'Doctor' || role == 'Pharmacist') {
          if (status == 'APPROVED') {
            return role == 'Doctor' ? const DoctorDashboard() : const PharmacyDashboard();
          } else {
            return role == 'Doctor' 
              ? const DoctorLicenseUploadScreen() 
              : const PharmacistLicenseUploadScreen();
          }
        }

        // Default routing for other roles (Patient, Caregiver-Friend/Relative)
        switch (role) {
          case 'Caregiver':
            return const CaregiverDashboard();
          case 'Patient':
            return const PatientDashboard();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
