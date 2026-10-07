import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'views/splash_screen.dart';
import 'views/doctor_dashboard.dart';
import 'views/caregiver_dashboard.dart';
import 'views/patient_dashboard_screen.dart';
import 'views/pharmacy_dashboard_screen.dart';
import 'services/notification_service.dart';
import 'views/login_screen.dart';
import 'views/doctor_license_upload_screen.dart';
import 'views/pharmacist_license_upload_screen.dart';
import 'views/nurse_license_upload_screen.dart';
// ViewModels imports
import 'view_models/ai_chat_view_model.dart';
import 'view_models/patient_dashboard_view_model.dart';
import 'view_models/doctor_dashboard_view_model.dart';
import 'view_models/caregiver_dashboard_view_model.dart';
import 'view_models/activity_view_model.dart';
import 'view_models/alarm_view_model.dart';
import 'view_models/admin_login_view_model.dart';
import 'view_models/admin_panel_view_model.dart';
import 'view_models/admin_license_view_model.dart';
import 'view_models/doctor_verification_view_model.dart';
import 'view_models/admin_feedback_view_model.dart';
import 'view_models/feedback_view_model.dart';
import 'view_models/admin_users_view_model.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiChatViewModel()),
        ChangeNotifierProvider(create: (_) => PatientDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => CaregiverDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => ActivityViewModel()),
        ChangeNotifierProvider(create: (_) => AlarmViewModel()),
        ChangeNotifierProvider(create: (_) => AdminLoginViewModel()),
        ChangeNotifierProvider(create: (_) => AdminPanelViewModel()),
        ChangeNotifierProvider(create: (_) => AdminLicenseViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorVerificationViewModel()),
        ChangeNotifierProvider(create: (_) => AdminFeedbackViewModel()),
        ChangeNotifierProvider(create: (_) => FeedbackViewModel()),
        ChangeNotifierProvider(create: (_) => AdminUsersViewModel()),
      ],
      child: const MedicareApp(),
    ),
  );
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
        if (role == 'Doctor' || role == 'Pharmacist') {
          if (status == 'APPROVED') {
            return role == 'Doctor' ? const DoctorDashboard() : const PharmacyDashboard();
          } else {
            return role == 'Doctor'
                ? const DoctorLicenseUploadScreen()
                : const PharmacistLicenseUploadScreen();
          }
        }

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
