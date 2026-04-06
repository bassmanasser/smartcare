import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

class SupportStaffHomeScreen extends StatelessWidget {
  const SupportStaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.translate('support_staff')),
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
        children: const [
          _TaskCard(title: 'Assigned Tasks', count: '0'),
          SizedBox(height: 12),
          _TaskCard(title: 'Open Requests', count: '0'),
          SizedBox(height: 12),
          _TaskCard(title: 'Completed Today', count: '0'),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String count;

  const _TaskCard({
    required this.title,
    required this.count,
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