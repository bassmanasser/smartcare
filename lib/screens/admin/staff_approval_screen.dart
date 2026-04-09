import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class StaffApprovalScreen extends StatefulWidget {
  final String institutionId;

  const StaffApprovalScreen({
    super.key,
    required this.institutionId,
  });

  @override
  State<StaffApprovalScreen> createState() => _StaffApprovalScreenState();
}

class _StaffApprovalScreenState extends State<StaffApprovalScreen> {
  bool _processing = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestsStream() {
    return FirebaseFirestore.instance
        .collection('staff_requests')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> _approveRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final data = doc.data();
      final uid = (data['uid'] ?? '').toString();
      final role = (data['role'] ?? '').toString();
      final name = (data['name'] ?? '').toString();
      final email = (data['email'] ?? '').toString();
      final phone = (data['phone'] ?? '').toString();
      final departmentName = (data['departmentName'] ?? '').toString();
      final employeeId = (data['employeeId'] ?? '').toString();
      final institutionName = (data['institutionName'] ?? '').toString();
      final medicalRole = (data['medicalRole'] ?? '').toString();
      final staffRole = (data['staffRole'] ?? '').toString();

      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'medicalRole': medicalRole,
        'staffRole': staffRole,
        'departmentName': departmentName,
        'employeeId': employeeId,
        'institutionId': widget.institutionId,
        'institutionName': institutionName,
        'approvalStatus': 'approved',
        'updatedAt': now,
      }, SetOptions(merge: true));

      await db.collection('staff_requests').doc(doc.id).set({
        'approvalStatus': 'approved',
        'approvedAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name approved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _rejectRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Reject request'),
            content: const Text(
              'Are you sure you want to reject this staff request?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok || _processing) return;
    setState(() => _processing = true);

    try {
      final data = doc.data();
      final uid = (data['uid'] ?? '').toString();

      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();

      if (uid.isNotEmpty) {
        await db.collection('users').doc(uid).set({
          'approvalStatus': 'rejected',
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      await db.collection('staff_requests').doc(doc.id).set({
        'approvalStatus': 'rejected',
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'doctor':
        return PETROL_DARK;
      case 'nurse':
        return Colors.teal;
      case 'staff':
        return ACCENT_ORANGE;
      default:
        return PETROL;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services_rounded;
      case 'nurse':
        return Icons.health_and_safety_rounded;
      case 'staff':
        return Icons.badge_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [PETROL_DARK, PETROL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff Approval Center',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Approve doctor, nurse, and staff requests using the hospital ID.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final role = (data['role'] ?? 'staff').toString();
    final name = (data['name'] ?? 'Unknown').toString();
    final email = (data['email'] ?? '--').toString();
    final phone = (data['phone'] ?? '--').toString();
    final employeeId = (data['employeeId'] ?? '--').toString();
    final department = (data['departmentName'] ?? 'No department').toString();
    final medicalRole = (data['medicalRole'] ?? '').toString();
    final staffRole = (data['staffRole'] ?? '').toString();
    final institutionName = (data['institutionName'] ?? '--').toString();

    String roleLine = role;
    if (role == 'doctor' && medicalRole.isNotEmpty) roleLine = medicalRole;
    if (role == 'staff' && staffRole.isNotEmpty) roleLine = staffRole;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _roleColor(role).withOpacity(0.12),
                  child: Icon(_roleIcon(role), color: _roleColor(role)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$roleLine • $department',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.email_rounded, email),
            const SizedBox(height: 8),
            _infoRow(Icons.phone_rounded, phone),
            const SizedBox(height: 8),
            _infoRow(Icons.badge_rounded, 'Employee ID: $employeeId'),
            const SizedBox(height: 8),
            _infoRow(
              Icons.local_hospital_rounded,
              'Hospital: $institutionName',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.business_rounded,
              'Hospital ID: ${widget.institutionId}',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : () => _rejectRequest(doc),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : () => _approveRequest(doc),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL_DARK,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 46,
            color: PETROL_DARK,
          ),
          SizedBox(height: 10),
          Text(
            'No pending requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'All current doctor, nurse, and staff requests have been reviewed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        backgroundColor: LIGHT_BG,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Staff Approvals',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _requestsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _header(),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Hospital ID: ${widget.institutionId}\nPending Requests: ${docs.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (docs.isEmpty) _emptyState(),
                ...docs.map(_requestCard),
              ],
            );
          },
        ),
      ),
    );
  }
}