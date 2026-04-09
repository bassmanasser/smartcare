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
  State<HospitalPeopleListScreen> createState() =>
      _HospitalPeopleListScreenState();
}

class _HospitalPeopleListScreenState extends State<HospitalPeopleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      data['fullName'],
      data['email'],
      data['phone'],
      data['department'],
      data['specialty'],
      data['employeeId'],
      data['patientId'],
    ];

    return values.any((value) => value.toString().toLowerCase().contains(q));
  }

  String _subtitleFor(Map<String, dynamic> data) {
    final parts = <String>[];

    final email = (data['email'] ?? '').toString().trim();
    final phone = (data['phone'] ?? '').toString().trim();
    final department = (data['department'] ?? '').toString().trim();
    final specialty = (data['specialty'] ?? '').toString().trim();

    if (email.isNotEmpty) parts.add(email);
    if (phone.isNotEmpty) parts.add(phone);
    if (department.isNotEmpty) parts.add(department);
    if (specialty.isNotEmpty) parts.add(specialty);

    return parts.isEmpty ? 'No extra details' : parts.join(' • ');
  }

  IconData _iconForRole() {
    switch (widget.roleFilter) {
      case 'doctor':
        return Icons.badge_outlined;
      case 'nurse':
        return Icons.local_hospital_outlined;
      case 'patient':
        return Icons.groups_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _emptyTitle() {
    if (widget.onlyToday && widget.roleFilter == 'patient') {
      return 'No patients today';
    }
    return 'No ${widget.title.toLowerCase()} found';
  }

  String _emptySubtitle() {
    if (_searchText.trim().isNotEmpty) {
      return 'Try changing the search text.';
    }
    if (widget.onlyToday) {
      return 'No records match today\'s filter.';
    }
    return 'No linked users found for this hospital.';
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForRole();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.95),
                  colorScheme.primaryContainer.withOpacity(0.90),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.onlyToday
                            ? 'Today\'s filtered list for this hospital'
                            : 'All linked ${widget.title.toLowerCase()} for this hospital',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchText = value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone, department...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchText.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Something went wrong: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = docs.where((doc) {
                  return _matchesSearch(doc.data());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _EmptyStateView(
                    icon: icon,
                    title: _emptyTitle(),
                    subtitle: _emptySubtitle(),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();

                    final name = (data['name'] ??
                            data['fullName'] ??
                            'Unnamed user')
                        .toString();

                    final subtitle = _subtitleFor(data);
                    final department = (data['department'] ?? '').toString();
                    final employeeId = (data['employeeId'] ?? '').toString();
                    final patientId = (data['patientId'] ?? '').toString();

                    return Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: colorScheme.primary.withOpacity(0.10),
                              ),
                              child: Icon(icon, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.72),
                                    ),
                                  ),
                                  if (department.isNotEmpty ||
                                      employeeId.isNotEmpty ||
                                      patientId.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (department.isNotEmpty)
                                          _InfoChip(label: department),
                                        if (employeeId.isNotEmpty)
                                          _InfoChip(label: 'ID: $employeeId'),
                                        if (patientId.isNotEmpty)
                                          _InfoChip(label: 'Patient ID: $patientId'),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
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

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}