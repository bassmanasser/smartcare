import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/welcome_screen.dart';
import 'patient/patient_home_screen.dart';
import 'doctor/doctor_home_screen.dart';
import 'parent/parent_home_screen.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/parent.dart';

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
    final role = data['role'] as String? ?? '';

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
      final p = Parent.fromJson(data);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParentHomeScreen(parent: p),
        ),
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
