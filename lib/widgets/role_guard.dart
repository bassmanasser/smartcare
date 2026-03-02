import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/auth/welcome_screen.dart';
import '../screens/user_type_selection_screen.dart';

class RoleGuard extends StatelessWidget {
  final String requiredRole; // parent/patient/doctor
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const UserTypeSelectionScreen();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final role = data['role'];

        // ✅ doctor لازم approved
        if (requiredRole == 'doctor') {
          final approved = data['doctorApproved'] == true;
          if (!(role == 'doctor' && approved)) {
            return const Scaffold(
              body: Center(child: Text("Access denied (Doctor approval required)")),
            );
          }
        } else {
          if (role != requiredRole) {
            return const Scaffold(body: Center(child: Text("Access denied")));
          }
        }

        return child;
      },
    );
  }
}
