import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../models/parent.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';

class ParentSettingsScreen extends StatelessWidget {
  final Parent parent;

  const ParentSettingsScreen({super.key, required this.parent});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: PETROL_DARK,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- 1. Parent ID Card (أهم جزء) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PETROL.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PETROL, width: 1),
              ),
              child: Column(
                children: [
                  const Text(
                    "YOUR PARENT ID",
                    style: TextStyle(
                      color: PETROL_DARK, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    parent.id,
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black87
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: parent.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ID Copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text("Copy ID"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Share this ID with the Patient to link accounts.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. Personal Info ---
            _SectionHeader(title: "Personal Information"),
            _InfoTile(icon: Icons.person, label: "Full Name", value: parent.name),
            _InfoTile(icon: Icons.badge, label: "National ID", value: parent.nationalId ?? '--'),
            _InfoTile(icon: Icons.phone, label: "Phone", value: parent.phone ?? '--'),
            _InfoTile(icon: Icons.email, label: "Email", value: parent.email ?? '--'),
            _InfoTile(icon: Icons.family_restroom, label: "Relation", value: parent.relation),

            const SizedBox(height: 24),

            // --- 3. Medical & Address ---
            _SectionHeader(title: "Additional Details"),
            _InfoTile(icon: Icons.home, label: "Address", value: parent.homeAddress ?? 'Not set'),
            
            // Family History List
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.history_edu, color: PETROL),
                        SizedBox(width: 12),
                        Text("Family Medical History", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (parent.familyMedicalHistory.isEmpty)
                      const Text("None recorded.", style: TextStyle(fontWeight: FontWeight.bold))
                    else
                      Wrap(
                        spacing: 8,
                        children: parent.familyMedicalHistory.map((disease) => Chip(
                          label: Text(disease),
                          backgroundColor: Colors.red.shade50,
                          labelStyle: const TextStyle(color: Colors.red),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            
            // Logout Button (Large)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Log Out", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: PETROL_DARK
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: PETROL),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          value, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
        ),
      ),
    );
  }
}