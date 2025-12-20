import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/parent.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';

class ParentHomeScreen extends StatelessWidget {
  final Parent parent;

  const ParentHomeScreen({super.key, required this.parent});

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
    final childrenPatients = app.patients.values
        .where((p) => p.parentId == parent.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Parent: ${parent.name}'),
        backgroundColor: PETROL_DARK,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: childrenPatients.isEmpty
          ? const Center(child: Text('No linked patients yet.'))
          : ListView.builder(
              itemCount: childrenPatients.length,
              itemBuilder: (context, index) {
                final p = childrenPatients[index];
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
