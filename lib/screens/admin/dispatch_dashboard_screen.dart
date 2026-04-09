import 'package:flutter/material.dart';

import 'department_management_screen.dart';
import 'emergency_queue_screen.dart';
import 'staff_approval_screen.dart';

class DispatchDashboardScreen extends StatelessWidget {
  final String institutionId;

  const DispatchDashboardScreen({
    super.key,
    required this.institutionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispatch Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            title: 'Emergency Queue',
            subtitle: 'See urgent and emergency incoming cases',
            icon: Icons.emergency,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyQueueScreen()),
              );
            },
          ),
          _MenuCard(
            title: 'Staff Approvals',
            subtitle: 'Approve doctors, nurses, and staff requests',
            icon: Icons.approval,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffApprovalScreen(institutionId: institutionId),
                ),
              );
            },
          ),
          _MenuCard(
            title: 'Departments',
            subtitle: 'Manage hospital departments and visibility',
            icon: Icons.account_tree_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DepartmentManagementScreen(
                    institutionId: institutionId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
