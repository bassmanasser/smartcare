import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DepartmentManagementScreen extends StatefulWidget {
  final String institutionId;

  const DepartmentManagementScreen({
    super.key,
    required this.institutionId,
  });

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _adding = false;

  CollectionReference<Map<String, dynamic>> get _departmentsRef =>
      FirebaseFirestore.instance.collection('institutions').doc(widget.institutionId).collection('departments');

  Future<void> _addDepartment() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _adding = true);
    try {
      await _departmentsRef.add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      _nameController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add department: $e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    await _departmentsRef.doc(id).update({'isActive': !current});
  }

  Future<void> _deleteDepartment(String id) async {
    await _departmentsRef.doc(id).delete();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Add department',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _adding ? null : _addDepartment,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _departmentsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No departments added yet'));
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final isActive = (data['isActive'] ?? true) == true;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text((data['name'] ?? '-').toString()),
                      subtitle: Text(isActive ? 'Active' : 'Inactive'),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            onPressed: () => _toggleActive(doc.id, isActive),
                            icon: Icon(isActive ? Icons.visibility_off : Icons.visibility),
                          ),
                          IconButton(
                            onPressed: () => _deleteDepartment(doc.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
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