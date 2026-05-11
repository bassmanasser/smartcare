import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/welcome_screen.dart';
import 'admin/admin_home_screen.dart';
import 'patient/patient_home_screen.dart';
import 'doctor/doctor_home_screen.dart';
import 'nurse/nurse_home_screen.dart';
import 'parent/parent_home_screen.dart';
import 'staff/staff_home_screen.dart';
import '../models/patient.dart';
import '../models/doctor.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 1));
    final user = _auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    final doc =
        await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    final data = doc.data()!;
    final role = (data['role'] ?? '').toString();
    final approvalStatus = (data['approvalStatus'] ?? 'approved').toString();

    if (approvalStatus != 'approved' &&
        ['doctor', 'nurse', 'staff', 'support_staff'].contains(role)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    if (role == 'patient') {
      data['id'] = doc.id;
      final p = Patient.fromJson(data);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatientHomeScreen(patient: p),
        ),
      );
    } else if (role == 'doctor') {
      data['id'] = doc.id;
      final d = Doctor.fromJson(data);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorHomeScreen(doctor: d),
        ),
      );
    } else if (role == 'parent') {
      data['id'] = doc.id;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParentHomeScreen(parent: data),
        ),
      );
    } else if (role == 'hospital_admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else if (role == 'nurse') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NurseHomeScreen()),
      );
    } else if (role == 'staff' || role == 'support_staff') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StaffHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
