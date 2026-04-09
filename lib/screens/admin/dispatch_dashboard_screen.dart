import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'emergency_queue_screen.dart';
import 'staff_approval_screen.dart';
import 'department_management_screen.dart';

class DispatchDashboardScreen extends StatelessWidget {
  const DispatchDashboardScreen({super.key});

  Stream<int> _countStream(String collection) {
    return FirebaseFirestore.instance.collection(collection).snapshots().map(
          (snapshot) => snapshot.docs.length,
        );
  }

  Stream<int> _pendingRequestsStream() {
    return FirebaseFirestore.instance
        .collection('staff_requests')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _emergencyPatientsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .where('queuePriority', isEqualTo: 'emergency')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Dispatch Dashboard'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PETROL_DARK, PETROL],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Medical Dispatching System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Patient → Institution → Triage → Department → Staff',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _liveCard(
                  title: 'Institutions',
                  icon: Icons.local_hospital,
                  stream: _countStream('institutions'),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _liveCard(
                  title: 'Departments',
                  icon: Icons.apartment,
                  stream: _countStream('departments'),
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _liveCard(
                  title: 'Pending Staff',
                  icon: Icons.pending_actions,
                  stream: _pendingRequestsStream(),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _liveCard(
                  title: 'Emergency Cases',
                  icon: Icons.emergency,
                  stream: _emergencyPatientsStream(),
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Management',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 12),
          _actionTile(
            context,
            icon: Icons.verified_user,
            title: 'Staff Approval',
            subtitle: 'Approve or reject medical staff requests',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffApprovalScreen(institutionId: '',)),
              );
            },
          ),
          _actionTile(
            context,
            icon: Icons.apartment,
            title: 'Department Management',
            subtitle: 'Add and manage institutional departments',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DepartmentManagementScreen(),
                ),
              );
            },
          ),
          _actionTile(
            context,
            icon: Icons.emergency_share,
            title: 'Emergency Queue',
            subtitle: 'Open high-priority and emergency cases',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyQueueScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _liveCard({
    required String title,
    required IconData icon,
    required Stream<int> stream,
    required Color color,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        );
      },
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: PETROL.withOpacity(0.12),
          child: Icon(icon, color: PETROL_DARK),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}