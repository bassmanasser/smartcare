import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class NursePatientsScreen extends StatefulWidget {
  final String nurseId;

  const NursePatientsScreen({
    super.key,
    required this.nurseId,
  });

  @override
  State<NursePatientsScreen> createState() => _NursePatientsScreenState();
}

class _NursePatientsScreenState extends State<NursePatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> patientData) {
    if (_searchText.trim().isEmpty) return true;

    final q = _searchText.trim().toLowerCase();
    final values = [
      patientData['name'],
      patientData['fullName'],
      patientData['email'],
      patientData['phone'],
      patientData['patientId'],
    ];

    return values.any((v) => v.toString().toLowerCase().contains(q));
  }

  Future<Map<String, dynamic>?> _loadPatient(String patientId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(patientId).get();
    return doc.data();
  }

  void _showPatientDetails(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['fullName'] ?? 'Unknown').toString();
    final patientId = (data['patientId'] ?? '-').toString();
    final email = (data['email'] ?? '-').toString();
    final phone = (data['phone'] ?? '-').toString();
    final age = (data['age'] ?? '-').toString();
    final gender = (data['gender'] ?? '-').toString();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _SheetInfoRow(label: 'Patient ID', value: patientId),
              _SheetInfoRow(label: 'Email', value: email),
              _SheetInfoRow(label: 'Phone', value: phone),
              _SheetInfoRow(label: 'Age', value: age),
              _SheetInfoRow(label: 'Gender', value: gender, isLast: true),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [PETROL_DARK, PETROL],
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
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Patients',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Professional patient list for the assigned nurse',
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
                hintText: 'Search by patient name, phone, email, patient ID...',
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
              stream: FirebaseFirestore.instance
                  .collection('care_links')
                  .where('linkedUserId', isEqualTo: widget.nurseId)
                  .where('linkedUserRole', isEqualTo: 'nurse')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Something went wrong: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No linked patients yet.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final linkData = docs[index].data();
                    final patientId = (linkData['patientId'] ?? '').toString();

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _loadPatient(patientId),
                      builder: (context, patientSnapshot) {
                        if (patientSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 0,
                              child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          );
                        }

                        final patientData = patientSnapshot.data;
                        if (patientData == null) return const SizedBox.shrink();
                        if (!_matchesSearch(patientData)) {
                          return const SizedBox.shrink();
                        }

                        final name = (patientData['name'] ??
                                patientData['fullName'] ??
                                'Unnamed Patient')
                            .toString();
                        final phone = (patientData['phone'] ?? '').toString();
                        final email = (patientData['email'] ?? '').toString();
                        final localPatientId =
                            (patientData['patientId'] ?? patientId).toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
                                backgroundColor: PETROL.withOpacity(0.12),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: PETROL_DARK,
                                ),
                              ),
                              title: Text(
                                name,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  [
                                    'Patient ID: $localPatientId',
                                    if (phone.isNotEmpty) phone,
                                    if (email.isNotEmpty) email,
                                  ].join('\n'),
                                ),
                              ),
                              isThreeLine: true,
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                              ),
                              onTap: () => _showPatientDetails(patientData),
                            ),
                          ),
                        );
                      },
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

class _SheetInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _SheetInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}