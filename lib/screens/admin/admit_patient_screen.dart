import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/hospital_patient_service.dart';
import '../../utils/constants.dart';

class AdmitPatientScreen extends StatefulWidget {
  final String institutionId;
  final String institutionName;

  const AdmitPatientScreen({
    super.key,
    required this.institutionId,
    required this.institutionName,
  });

  @override
  State<AdmitPatientScreen> createState() => _AdmitPatientScreenState();
}

class _AdmitPatientScreenState extends State<AdmitPatientScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();

  String _patientStatus = 'Waiting';
  String _priorityLevel = 'Medium';
  String _assignedDepartment = 'Emergency';

  String _selectedPatientUid = '';
  String _selectedPatientName = '';
  String _selectedDoctorId = '';
  String _selectedDoctorName = '';
  String _selectedNurseId = '';
  String _selectedNurseName = '';

  bool _loading = false;

  final List<String> _statuses = [
    'Waiting',
    'In Triage',
    'Assigned',
    'Under Observation',
    'Emergency',
    'Discharged',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  final List<String> _departments = [
    'Emergency',
    'Cardiology',
    'ICU',
    'Internal Medicine',
    'Pediatrics',
    'General',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAdmission() async {
    if (_selectedPatientUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await HospitalPatientService.admitPatientToHospital(
        patientUid: _selectedPatientUid,
        institutionId: widget.institutionId,
        institutionName: widget.institutionName,
        assignedDepartment: _assignedDepartment,
        patientStatus: _patientStatus,
        priorityLevel: _priorityLevel,
        assignedDoctorId: _selectedDoctorId,
        assignedDoctorName: _selectedDoctorName,
        assignedNurseId: _selectedNurseId,
        assignedNurseName: _selectedNurseName,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient admitted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _patientsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _staffStream(String role) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('role', isEqualTo: role)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Admit Patient'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Search Patient'),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by patient name',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _patientsStream(),
              builder: (context, snapshot) {
                var docs = snapshot.data?.docs ?? [];

                final q = _searchController.text.trim().toLowerCase();
                if (q.isNotEmpty) {
                  docs = docs.where((doc) {
                    final name =
                        (doc.data()['name'] ?? '').toString().toLowerCase();
                    return name.contains(q);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No patients found'),
                  );
                }

                return Column(
                  children: docs.take(6).map((doc) {
                    final data = doc.data();
                    final uid = doc.id;
                    final name = (data['name'] ?? 'Unknown').toString();
                    final selected = _selectedPatientUid == uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selected ? LIGHT_BG : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? PETROL_DARK : Colors.grey.shade300,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              selected ? PETROL_DARK : Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            color: selected ? Colors.white : PETROL_DARK,
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(uid),
                        trailing: selected
                            ? const Icon(Icons.check_circle, color: PETROL_DARK)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedPatientUid = uid;
                            _selectedPatientName = name;
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          if (_selectedPatientUid.isNotEmpty)
            _selectedBanner(_selectedPatientName, _selectedPatientUid),

          _sectionTitle('Routing Details'),
          _dropdownCard(
            label: 'Patient Status',
            value: _patientStatus,
            items: _statuses,
            onChanged: (v) => setState(() => _patientStatus = v!),
          ),
          const SizedBox(height: 12),
          _dropdownCard(
            label: 'Priority Level',
            value: _priorityLevel,
            items: _priorities,
            onChanged: (v) => setState(() => _priorityLevel = v!),
          ),
          const SizedBox(height: 12),
          _dropdownCard(
            label: 'Department',
            value: _assignedDepartment,
            items: _departments,
            onChanged: (v) => setState(() => _assignedDepartment = v!),
          ),
          const SizedBox(height: 18),

          _sectionTitle('Assign Doctor'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _staffStream('doctor'),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return _staffSelector(
                docs: docs,
                selectedId: _selectedDoctorId,
                onSelected: (id, name) {
                  setState(() {
                    _selectedDoctorId = id;
                    _selectedDoctorName = name;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 18),

          _sectionTitle('Assign Nurse'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _staffStream('nurse'),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return _staffSelector(
                docs: docs,
                selectedId: _selectedNurseId,
                onSelected: (id, name) {
                  setState(() {
                    _selectedNurseId = id;
                    _selectedNurseName = name;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 18),

          _sectionTitle('Notes'),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Admission notes / triage notes',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _saveAdmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: PETROL_DARK,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save),
              label: Text(_loading ? 'Saving...' : 'Admit Patient'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: PETROL_DARK,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _selectedBanner(String name, String uid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PETROL_DARK,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: PETROL_DARK),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  uid,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownCard({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _staffSelector({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String selectedId,
    required void Function(String id, String name) onSelected,
  }) {
    if (docs.isEmpty) {
      return const Text('No staff available');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: docs.take(6).map((doc) {
          final d = doc.data();
          final name = (d['name'] ?? 'Unknown').toString();
          final dept = (d['departmentName'] ?? '-').toString();
          final selected = selectedId == doc.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: selected ? LIGHT_BG : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? PETROL_DARK : Colors.grey.shade300,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: selected ? PETROL_DARK : Colors.grey.shade300,
                child: Icon(
                  Icons.badge,
                  color: selected ? Colors.white : PETROL_DARK,
                ),
              ),
              title: Text(name),
              subtitle: Text(dept),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: PETROL_DARK)
                  : null,
              onTap: () => onSelected(doc.id, name),
            ),
          );
        }).toList(),
      ),
    );
  }
}