import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_service.dart';
import '../../services/invite_service.dart';

class AdminInvitesScreen extends StatefulWidget {
  const AdminInvitesScreen({super.key});

  @override
  State<AdminInvitesScreen> createState() => _AdminInvitesScreenState();
}

class _AdminInvitesScreenState extends State<AdminInvitesScreen> {
  bool loading = true;
  bool allowed = false;

  final allowedEmailController = TextEditingController();
  String? lastCode;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final ok = await AdminService.isAdmin();
    if (mounted) {
      setState(() {
        allowed = ok;
        loading = false;
      });
    }
  }

  Future<void> _createInvite() async {
    final email = allowedEmailController.text.trim();

    final code = await InviteService.createDoctorInvite(
      allowedEmail: email.isEmpty ? null : email,
      autoApprove: true, // اختيارك
    );

    setState(() => lastCode = code);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invite created: $code")),
      );
    }
  }

  @override
  void dispose() {
    allowedEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!allowed) {
      return const Scaffold(
        body: Center(child: Text("You are not an admin.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Doctor Invite Codes")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: allowedEmailController,
              decoration: const InputDecoration(
                labelText: "Allowed Email (optional)",
                hintText: "Lock code to a specific doctor email",
              ),
            ),
            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: _createInvite,
              child: const Text("Generate Invite Code (auto-approve)"),
            ),

            const SizedBox(height: 24),

            if (lastCode != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Last generated code:",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        lastCode!,
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: lastCode!),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Copied ✅")),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}