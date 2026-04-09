import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  State<HospitalPeopleListScreen> createState() => _HospitalPeopleListScreenState();
}

class _HospitalPeopleListScreenState extends State<HospitalPeopleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('role', isEqualTo: widget.roleFilter);

    if (widget.onlyToday) {
      query = query.where('arrivalDayKey', isEqualTo: _todayKey());
    }

    return query;
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchText.trim().isEmpty) return true;
    final q = _searchText.trim().toLowerCase();
    final values = [
      data['name'],
      data['email'],
      data['phone'],
      data['department'],
      data['employeeId'],
      data['licenseNumber'],
      data['specialty'],
    ];
    return values.any((value) => value.toString().toLowerCase().contains(q));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchText = value),
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = (snapshot.data?.docs ?? [])
                    .where((doc) => _matchesSearch(doc.data()))
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No records found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final subtitle = <String>[
                      if ((data['email'] ?? '').toString().isNotEmpty)
                        'Email: ${data['email']}',
                      if ((data['phone'] ?? '').toString().isNotEmpty)
                        'Phone: ${data['phone']}',
                      if ((data['department'] ?? '').toString().isNotEmpty)
                        'Department: ${data['department']}',
                      if ((data['employeeId'] ?? '').toString().isNotEmpty)
                        'Employee ID: ${data['employeeId']}',
                      if ((data['specialty'] ?? '').toString().isNotEmpty)
                        'Specialty: ${data['specialty']}',
                    ].join('\n');

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          child: Text(
                            ((data['name'] ?? '?').toString().trim().isNotEmpty)
                                ? (data['name'] as String).trim()[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(
                          (data['name'] ?? 'Unknown').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                        isThreeLine: subtitle.contains('\n'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
