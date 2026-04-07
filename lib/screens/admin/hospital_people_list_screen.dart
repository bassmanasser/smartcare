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

    final stream = isPendingRequests
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
          var docs = snapshot.data?.docs ?? [];

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
            docs = docs.where((doc) {
              final d = doc.data();
              final q = search.toLowerCase();
              return (d['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (d['departmentName'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q) ||
                  (d['employeeId'] ?? '').toString().toLowerCase().contains(q) ||
                  (d['role'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (d['name'] ?? '-').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: PETROL_DARK,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip('Role: ${d['role'] ?? '-'}'),
                              _chip(
                                  'Dept: ${d['departmentName'] ?? d['assignedDepartment'] ?? '-'}'),
                              _chip(
                                  'ID: ${d['employeeId'] ?? d['patientId'] ?? '-'}'),
                              _chip(
                                  'Status: ${d['approvalStatus'] ?? d['patientStatus'] ?? '-'}'),
                              _chip('Priority: ${d['priorityLevel'] ?? '-'}'),
                            ],
                          ),
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
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}