import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Account Type'),
        actions: [
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
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select your role',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Logged in as: ${user?.email ?? 'No email found'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your role to complete the registration form.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _RoleCard(
              icon: Icons.local_hospital_rounded,
              title: 'Hospital / Institution Admin',
              subtitle: 'Create and manage a hospital account.',
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
              title: 'Doctor',
              subtitle: 'Join an existing hospital using Hospital ID.',
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
              title: 'Nurse',
              subtitle: 'Register under a hospital and wait for approval.',
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
              title: 'Staff',
              subtitle: 'Join the hospital team using Hospital ID.',
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
              title: 'Patient',
              subtitle: 'Complete the patient intake profile.',
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
              title: 'Parent',
              subtitle: 'Create a parent account linked to patient care.',
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