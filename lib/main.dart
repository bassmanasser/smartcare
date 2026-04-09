import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/doctor.dart';
import 'models/patient.dart';
import 'providers/app_state.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/doctor/doctor_home_screen.dart';
import 'screens/nurse/nurse_home_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/staff/staff_home_screen.dart';
import 'screens/user_type_selection_screen.dart';
import 'services/auth_service.dart';
import 'services/ble_monitor_manager.dart';
import 'utils/localization.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await BleMonitorManager.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F5C63),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F5C63),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF0F5C63),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF0F5C63).withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  ThemeData _darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F5C63),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      cardColor: const Color(0xFF171C22),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF111827),
        indicatorColor: Colors.tealAccent.withOpacity(0.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF171C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'SmartCare',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: appState.currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomeScreen();
        }

        return UserDataFetcher(uid: snapshot.data!.uid);
      },
    );
  }
}

class UserDataFetcher extends StatefulWidget {
  final String uid;

  const UserDataFetcher({super.key, required this.uid});

  @override
  State<UserDataFetcher> createState() => _UserDataFetcherState();
}

class _UserDataFetcherState extends State<UserDataFetcher> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
  }

  bool _isStaffRole(String role) {
    return [
      'doctor',
      'nurse',
      'support_staff',
      'staff',
    ].contains(role);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const UserTypeSelectionScreen();
        }

        try {
          final userData = userSnapshot.data!.data() ?? {};
          final role = (userData['role'] ?? 'patient').toString();
          final approvalStatus =
              (userData['approvalStatus'] ?? 'approved').toString();

          if (_isStaffRole(role) && approvalStatus != 'approved') {
            return PendingApprovalScreen(
              role: role,
              status: approvalStatus,
              institutionName:
                  (userData['institutionName'] ?? '').toString(),
            );
          }

          if (role == 'patient') {
            final p = Patient.fromJson({...userData, 'id': widget.uid});
            return PatientHomeScreen(patient: p);
          }

          if (role == 'hospital_admin') {
            return const AdminHomeScreen();
          }

          if (role == 'doctor') {
            final d = Doctor.fromJson({...userData, 'id': widget.uid});
            return DoctorHomeScreen(doctor: d);
          }

          if (role == 'nurse') {
            return const NurseHomeScreen();
          }

          if (role == 'support_staff' || role == 'staff') {
            return const StaffHomeScreen();
          }

          return const Scaffold(
            body: Center(child: Text('Unknown user role')),
          );
        } catch (e) {
          return Scaffold(
            body: Center(child: Text('Error parsing user data: $e')),
          );
        }
      },
    );
  }
}