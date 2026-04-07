import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'admin/hospital_admin_signup_screen.dart';
import 'doctor/doctor_signup_screen.dart';
import 'auth/login_screen.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Choose Account Type'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            const Text(
              'Welcome to SmartCare',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: PETROL_DARK,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select how you want to join the system.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.local_hospital,
              title: 'Hospital / Institution Admin',
              subtitle: 'Create a hospital account and manage doctors, nurses, and staff.',
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
              icon: Icons.medical_services,
              title: 'Doctor',
              subtitle: 'Join an existing hospital using Hospital ID.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorSignupScreen(
                      role: 'doctor',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.health_and_safety,
              title: 'Nurse',
              subtitle: 'Register under a hospital and wait for admin approval.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorSignupScreen(
                      role: 'nurse',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.badge,
              title: 'Staff',
              subtitle: 'Join your hospital team with your Hospital ID.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorSignupScreen(
                      role: 'staff',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Already have an account? Login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PETROL_DARK,
                side: const BorderSide(color: PETROL_DARK),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: LIGHT_BG,
                child: Icon(icon, color: PETROL_DARK, size: 28),
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
                        color: PETROL_DARK,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: PETROL_DARK),
            ],
          ),
        ),
      ),
    );
  }
}