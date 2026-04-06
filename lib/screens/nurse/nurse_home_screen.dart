import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

class NurseHomeScreen extends StatelessWidget {
  const NurseHomeScreen({super.key});

  Future<Map<String, dynamic>?> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data ?? {};
        final name = userData['name'] ?? '';
        final institutionName = userData['institutionName'] ?? '';
        final departmentName = userData['departmentName'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text(tr.translate('nurse')),
            backgroundColor: PETROL_DARK,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final appState =
                      Provider.of<AppState>(context, listen: false);
                  if (value == 'ar') appState.changeLanguage('ar');
                  if (value == 'en') appState.changeLanguage('en');
                  if (value == 'logout') await FirebaseAuth.instance.signOut();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'ar', child: Text(tr.translate('arabic'))),
                  PopupMenuItem(value: 'en', child: Text(tr.translate('english'))),
                  PopupMenuItem(value: 'logout', child: Text(tr.translate('logout'))),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(
                title: '$name',
                subtitle: '$institutionName • $departmentName',
                icon: Icons.local_hospital,
              ),
              const SizedBox(height: 16),
              _SimpleCard(
                title: tr.translate('assigned_patients'),
                value: '0',
              ),
              const SizedBox(height: 12),
              _SimpleCard(
                title: tr.translate('latest_alerts'),
                value: '0',
              ),
              const SizedBox(height: 12),
              _SimpleCard(
                title: tr.translate('active_cases'),
                value: '0',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PETROL_DARK,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(icon, color: PETROL_DARK),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleCard extends StatelessWidget {
  final String title;
  final String value;

  const _SimpleCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: PETROL_DARK,
            ),
          ),
        ],
      ),
    );
  }
}