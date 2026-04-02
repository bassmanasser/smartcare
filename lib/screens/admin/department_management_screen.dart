import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final _institutionIdController = TextEditingController();
  final _departmentNameController = TextEditingController();

  @override
  void dispose() {
    _institutionIdController.dispose();
    _departmentNameController.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> _addDepartment() async {
    final institutionId = _normalize(_institutionIdController.text);
    final departmentName = _departmentNameController.text.trim();
    final departmentId = _normalize(departmentName);

    if (institutionId.isEmpty || departmentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter institution id and department name')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('departments')
          .doc('${institutionId}_$departmentId')
          .set({
        'id': departmentId,
        'institutionId': institutionId,
        'name': departmentName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('institutions')
          .doc(institutionId)
          .set({
        'departments': FieldValue.arrayUnion([departmentName]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _departmentNameController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding department: $e')),
      );
    }
  }

  Future<void> _deleteDepartment(String docId, String institutionId, String name) async {
    try {
      await FirebaseFirestore.instance.collection('departments').doc(docId).delete();

      await FirebaseFirestore.instance
          .collection('institutions')
          .doc(institutionId)
          .set({
        'departments': FieldValue.arrayRemove([name]),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department removed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typedInstitution = _normalize(_institutionIdController.text);

    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Department Management'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _institutionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Institution ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_hospital),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _departmentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addDepartment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PETROL_DARK,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Department'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: typedInstitution.isEmpty
                ? const Center(
                    child: Text('Enter Institution ID to view departments'),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('departments')
                        .where('institutionId', isEqualTo: typedInstitution)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('No departments found'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: PETROL,
                                child: Icon(Icons.apartment, color: Colors.white),
                              ),
                              title: Text((data['name'] ?? '--').toString()),
                              subtitle: Text(
                                'Institution: ${(data['institutionId'] ?? '--').toString()}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDepartment(
                                  doc.id,
                                  (data['institutionId'] ?? '').toString(),
                                  (data['name'] ?? '').toString(),
                                ),
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