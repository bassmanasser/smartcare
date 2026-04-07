import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class HospitalPeopleListScreen extends StatefulWidget {
  final String institutionId;
  final String title;
  final String roleFilter;
  final bool onlyToday;

  const HospitalPeopleListScreen({
    super.key,
    required this.institutionId,
    required this.title,
    required this.roleFilter,
    this.onlyToday = false,
  });

  @override
  State<HospitalPeopleListScreen> createState() =>
      _HospitalPeopleListScreenState();
}

class _HospitalPeopleListScreenState extends State<HospitalPeopleListScreen> {
  String search = '';

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final isPendingRequests = widget.roleFilter == 'pending_requests';

    final Stream<QuerySnapshot<Map<String, dynamic>>> stream = isPendingRequests
        ? FirebaseFirestore.instance
            .collection('staff_requests')
            .where('institutionId', isEqualTo: widget.institutionId)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('users')
            .where('institutionId', isEqualTo: widget.institutionId)
            .snapshots();

    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
              snapshot.data?.docs ?? [];

          if (isPendingRequests) {
            docs = docs.where((doc) {
              final d = doc.data();
              return (d['approvalStatus'] ?? '').toString() == 'pending';
            }).toList();
          } else {
            if (widget.roleFilter.isNotEmpty) {
              docs = docs.where((doc) {
                return (doc.data()['role'] ?? '').toString() ==
                    widget.roleFilter;
              }).toList();
            }

            if (widget.onlyToday) {
              docs = docs.where((doc) {
                return (doc.data()['arrivalDayKey'] ?? '').toString() ==
                    _todayKey();
              }).toList();
            }
          }

          if (search.trim().isNotEmpty) {
            final q = search.toLowerCase();
            docs = docs.where((doc) {
              final d = doc.data();
              return (d['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (d['email'] ?? '').toString().toLowerCase().contains(q) ||
                  (d['departmentName'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q) ||
                  (d['employeeId'] ?? '').toString().toLowerCase().contains(q) ||
                  (d['patientId'] ?? '').toString().toLowerCase().contains(q) ||
                  (d['role'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, department, ID...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CountChip(label: 'Total', value: docs.length.toString()),
                    if (widget.onlyToday) ...[
                      const SizedBox(width: 8),
                      const _SimpleBadge(text: 'Today'),
                    ],
                    if (widget.roleFilter.isNotEmpty &&
                        widget.roleFilter != 'pending_requests') ...[
                      const SizedBox(width: 8),
                      _SimpleBadge(text: widget.roleFilter.toUpperCase()),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'No records found.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final d = docs[index].data();

                          final name = (d['name'] ?? '-').toString();
                          final role = (d['role'] ??
                                  d['medicalRole'] ??
                                  d['staffRole'] ??
                                  '-')
                              .toString();
                          final department = (d['departmentName'] ??
                                  d['assignedDepartment'] ??
                                  '-')
                              .toString();
                          final id = (d['employeeId'] ??
                                  d['patientId'] ??
                                  d['uid'] ??
                                  '-')
                              .toString();
                          final status = (d['approvalStatus'] ??
                                  d['patientStatus'] ??
                                  '-')
                              .toString();
                          final email = (d['email'] ?? '-').toString();
                          final phone = (d['phone'] ?? '-').toString();
                          final priority =
                              (d['priorityLevel'] ?? '-').toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: LIGHT_BG,
                                      child: Icon(
                                        widget.roleFilter == 'patient'
                                            ? Icons.personal_injury
                                            : Icons.person,
                                        color: PETROL_DARK,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: PETROL_DARK,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: LIGHT_BG,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: PETROL_DARK,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _chip('Role: $role'),
                                    _chip('Dept: $department'),
                                    _chip('ID: $id'),
                                    if (priority != '-') _chip('Priority: $priority'),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _infoRow('Email', email),
                                const SizedBox(height: 8),
                                _infoRow('Phone', phone),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: LIGHT_BG,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: PETROL_DARK,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final String value;

  const _CountChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: PETROL_DARK,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SimpleBadge extends StatelessWidget {
  final String text;

  const _SimpleBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: PETROL_DARK,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}