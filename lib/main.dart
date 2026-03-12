import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ✅ ADD
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/ble_monitor_manager.dart';

import 'providers/app_state.dart';
import 'services/auth_service.dart';
import 'utils/localization.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/user_type_selection_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/doctor/doctor_home_screen.dart';
import 'screens/parent/parent_home_screen.dart';

import 'models/patient.dart';
import 'models/doctor.dart';
import 'models/parent.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ADD: مهم جدًا لتشغيل Foreground Service
  FlutterForegroundTask.initCommunicationPort();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ ADD: تهيئة إعدادات الـ Foreground Service مرة واحدة
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'SmartCare',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: appState.currentLocale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
      ),
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
  Future<DocumentSnapshot>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Error loading data. Check internet.")),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const UserTypeSelectionScreen();
        }

        try {
          final userData =
              userSnapshot.data!.data() as Map<String, dynamic>;
          String role = userData['role'] ?? 'patient';

          if (role == 'patient') {
            Patient p = Patient.fromJson(userData..['id'] = widget.uid);
            return PatientHomeScreen(patient: p);
          } else if (role == 'doctor') {
            Doctor d = Doctor.fromJson(userData..['id'] = widget.uid);
            return DoctorHomeScreen(doctor: d);
          } else if (role == 'parent') {
            return const ParentHomeScreen();
          } else {
            return const Scaffold(
              body: Center(child: Text("Unknown User Role")),
            );
          }
        } catch (e) {
          return const Scaffold(
            body: Center(child: Text("Error parsing user data")),
          );
        }
      },
    );
  }
}
