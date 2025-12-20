import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:smartcare/screens/parent/parent_signup_screen.dart';

import '../providers/app_state.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/parent.dart';

import '../screens/patient/patient_home_screen.dart';
import '../screens/doctor/doctor_home_screen.dart';
import '../screens/parent/parent_home_screen.dart';
import '../screens/user_type_selection_screen.dart';
import '../screens/auth/welcome_screen.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn(
      BuildContext context, String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _handleNavigation(context, cred.user!);
  }

  Future<void> signUp(
      BuildContext context, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // لسه مفيش role ولا بيانات → وديه يختار نوعه
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const UserTypeSelectionScreen(),
        ),
        (r) => false,
      );
    }
  }

  Future<void> _handleNavigation(BuildContext context, User user) async {
    if (!context.mounted) return;

    final app = Provider.of<AppState>(context, listen: false);

    final Patient? patient =
        app.patients.values.firstWhereOrNull((p) => p.id == user.uid);
    final Doctor? doctor =
        app.doctors.values.firstWhereOrNull((d) => d.id == user.uid);
    final Parent? parent =
        app.parents.values.firstWhereOrNull((p) => p.id == user.uid);

    if (patient != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PatientHomeScreen(patient: patient),
        ),
        (r) => false,
      );
    } else if (doctor != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorHomeScreen(doctor: doctor),
        ),
        (r) => false,
      );
    } else if (parent != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ParentHomeScreen(parent: parent),
        ),
        (r) => false,
      );
    } else {
      // مفيش بيانات في Firestore → يختار نوعه ويكمّل signup
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const UserTypeSelectionScreen(),
        ),
        (r) => false,
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (r) => false,
      );
    }
  }
}
