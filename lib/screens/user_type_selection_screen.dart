import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/localization.dart';
import '../widgets/language_picker.dart';
import 'admin/hospital_admin_signup_screen.dart';
import 'doctor/doctor_signup_screen.dart';
import 'parent/parent_signup_screen.dart';
import 'patient/patient_signup_screen.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('choose_role')),
        actions: [
          IconButton(
            tooltip: lang.translate('language'),
            onPressed: () => showLanguagePicker(context),
            icon: const Icon(Icons.language_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                '${lang.translate('select_how_to_use')}\n${user?.email ?? ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _RoleCard(
              icon: Icons.local_hospital_rounded,
              title: lang.translate('hospital_admin'),
              subtitle: lang.translate('hospital_admin_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HospitalAdminSignupScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.medical_services_rounded,
              title: lang.translate('doctor'),
              subtitle: lang.translate('doctor_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorSignupScreen(role: 'doctor'),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.health_and_safety_rounded,
              title: lang.translate('nurse'),
              subtitle: lang.translate('nurse_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorSignupScreen(role: 'nurse'),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.badge_outlined,
              title: lang.translate('staff'),
              subtitle: lang.translate('staff_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorSignupScreen(role: 'staff'),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.favorite_rounded,
              title: lang.translate('patient'),
              subtitle: lang.translate('patient_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientSignUpScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.family_restroom_rounded,
              title: lang.translate('parent'),
              subtitle: lang.translate('parent_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParentSignUpScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.10),
                child: Icon(icon, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.72,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
