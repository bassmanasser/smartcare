import 'package:flutter/material.dart';
import '../auth/auth_screen.dart';

class DoctorInviteScreen extends StatelessWidget {
  const DoctorInviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Access")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 50),
            const SizedBox(height: 12),
            const Text(
              "Invite code is disabled in this version.\nDoctors can sign up normally.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                child: const Text("Go to Login / Sign Up"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
