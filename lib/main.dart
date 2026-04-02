import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/doctor.dart';
import 'models/parent.dart';
import 'models/patient.dart';
import 'providers/app_state.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/doctor/doctor_home_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/patient/patient_home_screen.dart';
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
        scaffoldBackgroundColor: Colors.grey,
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
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  
  get Parent => null;

  @override
  void initState() {
    super.initState();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
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

          if (role == 'patient') {
            final p = Patient.fromJson({...userData, 'id': widget.uid});
            return PatientHomeScreen(patient: p);
          }

          if (role == 'parent') {
            final p = Parent.fromJson({...userData, 'id': widget.uid});
            return ParentHomeScreen(parent: p);
          }

          if (role == 'hospital_admin') {
            return const AdminHomeScreen();
          }

          if (role == 'doctor' || role == 'nurse' || role == 'triage_staff') {
            final d = Doctor.fromJson({...userData, 'id': widget.uid});
            return DoctorHomeScreen(doctor: d);
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