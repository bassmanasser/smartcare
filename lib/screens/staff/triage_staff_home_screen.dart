import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

class TriageStaffHomeScreen extends StatelessWidget {
  const TriageStaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.translate('triage_staff')),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final appState = Provider.of<AppState>(context, listen: false);
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
          _QueueCard(
            title: tr.translate('incoming_queue'),
            count: '0',
            icon: Icons.route,
          ),
          const SizedBox(height: 12),
          _QueueCard(
            title: tr.translate('severity'),
            count: '0',
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 12),
          _QueueCard(
            title: tr.translate('priority'),
            count: '0',
            icon: Icons.priority_high,
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;

  const _QueueCard({
    required this.title,
    required this.count,
    required this.icon,
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
          CircleAvatar(
            backgroundColor: PETROL_DARK,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PETROL_DARK,
            ),
          ),
        ],
      ),
    );
  }
}