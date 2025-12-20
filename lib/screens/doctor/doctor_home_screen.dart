import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorHomeScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorHomeScreen({super.key, required this.doctor});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final myPatients = app.patients.values
        .where((p) => p.doctorId == doctor.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${doctor.name}'),
        backgroundColor: PETROL_DARK,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: myPatients.isEmpty
          ? const Center(child: Text('No patients assigned yet.'))
          : ListView.builder(
              itemCount: myPatients.length,
              itemBuilder: (context, index) {
                final p = myPatients[index];
                final vitals = app.getVitalsForPatient(p.id);
                final last = vitals.isNotEmpty ? vitals.first : null;
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    last == null
                        ? 'No vitals yet'
                        : 'HR: ${last.hr} bpm, SpO2: ${last.spo2}%',
                  ),
                );
              },
            ),
    );
  }
}
