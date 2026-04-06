import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../auth/email_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        title: const Text('SmartCare'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final appState = Provider.of<AppState>(context, listen: false);
              if (value == 'ar') appState.changeLanguage('ar');
              if (value == 'en') appState.changeLanguage('en');
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'ar',
                child: Text(tr.translate('arabic')),
              ),
              PopupMenuItem(
                value: 'en',
                child: Text(tr.translate('english')),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: PETROL_DARK,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.translate('welcome'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SmartCare',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr.translate('select_how_to_use'),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _RoleCard(
            title: tr.translate('hospital_admin'),
            subtitle: tr.translate('hospital_admin_desc'),
            icon: Icons.admin_panel_settings,
            onTap: () => _openAuth(context, 'hospital_admin'),
          ),
          const SizedBox(height: 14),

          _RoleCard(
            title: tr.translate('doctor'),
            subtitle: tr.translate('doctor_desc'),
            icon: Icons.medical_services,
            onTap: () => _openAuth(context, 'doctor'),
          ),
          const SizedBox(height: 14),

          _RoleCard(
            title: tr.translate('nurse'),
            subtitle: tr.translate('nurse_desc'),
            icon: Icons.local_hospital,
            onTap: () => _openAuth(context, 'nurse'),
          ),
          const SizedBox(height: 14),

          _RoleCard(
            title: tr.translate('triage_staff'),
            subtitle: tr.translate('triage_desc'),
            icon: Icons.route,
            onTap: () => _openAuth(context, 'triage_staff'),
          ),
          const SizedBox(height: 14),

          _RoleCard(
            title: tr.translate('support_staff'),
            subtitle: tr.translate('staff_desc'),
            icon: Icons.badge,
            onTap: () => _openAuth(context, 'support_staff'),
          ),
          const SizedBox(height: 14),

          _RoleCard(
            title: tr.translate('patient'),
            subtitle: tr.translate('patient_desc'),
            icon: Icons.favorite,
            onTap: () => _openAuth(context, 'patient'),
          ),
          const SizedBox(height: 14),

          _RoleCard(
            title: tr.translate('parent'),
            subtitle: tr.translate('parent_desc'),
            icon: Icons.family_restroom,
            onTap: () => _openAuth(context, 'parent'),
          ),
        ],
      ),
    );
  }

  void _openAuth(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailAuthScreen(
          role: role,
          startAsLogin: true,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: PETROL.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: PETROL_DARK,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: PETROL_DARK,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}