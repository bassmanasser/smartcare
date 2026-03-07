import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/care_link.dart';
import '../../services/care_link_service.dart';
import '../../utils/constants.dart';

class LinkedAccountsScreen extends StatefulWidget {
  final String patientId;
  const LinkedAccountsScreen({super.key, required this.patientId});

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  final CareLinkService _service = CareLinkService();

  final TextEditingController _doctorIdController = TextEditingController();
  final TextEditingController _doctorLabelController =
      TextEditingController(text: 'Cardiologist');
  final TextEditingController _doctorNotesController = TextEditingController();

  final TextEditingController _parentIdController = TextEditingController();
  final TextEditingController _parentLabelController =
      TextEditingController(text: 'Family');
  final TextEditingController _parentNotesController = TextEditingController();

  bool doctorPrimary = false;
  bool doctorVitals = true;
  bool doctorReports = true;
  bool doctorMedications = true;
  bool doctorNotes = true;
  bool doctorAlerts = true;
  bool doctorCarePlan = false;

  bool parentVitals = true;
  bool parentReports = true;
  bool parentMedications = true;
  bool parentAlerts = true;

  bool _loading = false;

  @override
  void dispose() {
    _doctorIdController.dispose();
    _doctorLabelController.dispose();
    _doctorNotesController.dispose();
    _parentIdController.dispose();
    _parentLabelController.dispose();
    _parentNotesController.dispose();
    super.dispose();
  }

  Future<void> _sendDoctorRequest() async {
    if (_doctorIdController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      await _service.sendDoctorRequest(
        patientId: widget.patientId,
        doctorId: _doctorIdController.text.trim(),
        requestedBy: widget.patientId,
        relationshipLabel: _doctorLabelController.text.trim(),
        isPrimary: doctorPrimary,
        canViewVitals: doctorVitals,
        canViewReports: doctorReports,
        canViewMedications: doctorMedications,
        canWriteNotes: doctorNotes,
        canReceiveAlerts: doctorAlerts,
        canManageCarePlan: doctorCarePlan,
        notes: _doctorNotesController.text.trim(),
      );

      _doctorIdController.clear();
      _doctorNotesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor request sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _sendParentRequest() async {
    if (_parentIdController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      await _service.sendParentRequest(
        patientId: widget.patientId,
        parentId: _parentIdController.text.trim(),
        requestedBy: widget.patientId,
        relationshipLabel: _parentLabelController.text.trim(),
        canViewVitals: parentVitals,
        canViewReports: parentReports,
        canViewMedications: parentMedications,
        canReceiveAlerts: parentAlerts,
        notes: _parentNotesController.text.trim(),
      );

      _parentIdController.clear();
      _parentNotesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family request sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
    setState(() => _loading = false);
  }

  void _showEditPermissionsDialog(CareLink link) {
    bool canViewVitals = link.canViewVitals;
    bool canViewReports = link.canViewReports;
    bool canViewMedications = link.canViewMedications;
    bool canWriteNotes = link.canWriteNotes;
    bool canReceiveAlerts = link.canReceiveAlerts;
    bool canManageCarePlan = link.canManageCarePlan;
    final notesController = TextEditingController(text: link.notes);
    final labelController = TextEditingController(text: link.relationshipLabel);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Relationship'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship Label',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes on relationship',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: canViewVitals,
                    onChanged: (v) => setLocal(() => canViewVitals = v ?? false),
                    title: const Text('Can view vitals'),
                  ),
                  CheckboxListTile(
                    value: canViewReports,
                    onChanged: (v) => setLocal(() => canViewReports = v ?? false),
                    title: const Text('Can view reports'),
                  ),
                  CheckboxListTile(
                    value: canViewMedications,
                    onChanged: (v) =>
                        setLocal(() => canViewMedications = v ?? false),
                    title: const Text('Can view medications'),
                  ),
                  CheckboxListTile(
                    value: canWriteNotes,
                    onChanged: (v) => setLocal(() => canWriteNotes = v ?? false),
                    title: const Text('Can write notes'),
                  ),
                  CheckboxListTile(
                    value: canReceiveAlerts,
                    onChanged: (v) =>
                        setLocal(() => canReceiveAlerts = v ?? false),
                    title: const Text('Can receive alerts'),
                  ),
                  CheckboxListTile(
                    value: canManageCarePlan,
                    onChanged: (v) =>
                        setLocal(() => canManageCarePlan = v ?? false),
                    title: const Text('Can manage care plan'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.updatePermissions(
                linkId: link.id,
                canViewVitals: canViewVitals,
                canViewReports: canViewReports,
                canViewMedications: canViewMedications,
                canWriteNotes: canWriteNotes,
                canReceiveAlerts: canReceiveAlerts,
                canManageCarePlan: canManageCarePlan,
                notes: notesController.text.trim(),
                relationshipLabel: labelController.text.trim(),
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(LinkStatus s) {
    switch (s) {
      case LinkStatus.pending:
        return Colors.orange;
      case LinkStatus.approved:
        return Colors.green;
      case LinkStatus.rejected:
        return Colors.red;
      case LinkStatus.removed:
        return Colors.grey;
      case LinkStatus.blocked:
        return Colors.black54;
    }
  }

  String _statusText(LinkStatus s) {
    switch (s) {
      case LinkStatus.pending:
        return 'Pending';
      case LinkStatus.approved:
        return 'Approved';
      case LinkStatus.rejected:
        return 'Rejected';
      case LinkStatus.removed:
        return 'Removed';
      case LinkStatus.blocked:
        return 'Blocked';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Linked Doctors & Family'),
        backgroundColor: PETROL_DARK,
      ),
      body: StreamBuilder<List<CareLink>>(
        stream: _service.patientLinksStream(widget.patientId),
        builder: (context, snapshot) {
          final links = snapshot.data ?? [];
          final doctors =
              links.where((e) => e.linkedUserRole == LinkUserRole.doctor).toList();
          final parents =
              links.where((e) => e.linkedUserRole == LinkUserRole.parent).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Invite Doctor'),
              _buildInviteDoctorCard(),
              const SizedBox(height: 18),
              _buildSectionTitle('Invite Family Member'),
              _buildInviteParentCard(),
              const SizedBox(height: 18),
              _buildSectionTitle('Linked Doctors'),
              ...doctors.map(_buildLinkCard),
              if (doctors.isEmpty) _buildEmptyCard('No doctors yet'),
              const SizedBox(height: 18),
              _buildSectionTitle('Linked Family'),
              ...parents.map(_buildLinkCard),
              if (parents.isEmpty) _buildEmptyCard('No family members yet'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: PETROL_DARK,
        ),
      ),
    );
  }

  Widget _buildInviteDoctorCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: _doctorIdController,
              decoration: const InputDecoration(
                labelText: 'Doctor ID / Invite Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _doctorLabelController,
              decoration: const InputDecoration(
                labelText: 'Relationship Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _doctorNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes on relationship',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: doctorPrimary,
              onChanged: (v) => setState(() => doctorPrimary = v ?? false),
              title: const Text('Primary Doctor'),
            ),
            CheckboxListTile(
              value: doctorVitals,
              onChanged: (v) => setState(() => doctorVitals = v ?? false),
              title: const Text('Can view vitals'),
            ),
            CheckboxListTile(
              value: doctorReports,
              onChanged: (v) => setState(() => doctorReports = v ?? false),
              title: const Text('Can view reports'),
            ),
            CheckboxListTile(
              value: doctorMedications,
              onChanged: (v) => setState(() => doctorMedications = v ?? false),
              title: const Text('Can view medications'),
            ),
            CheckboxListTile(
              value: doctorNotes,
              onChanged: (v) => setState(() => doctorNotes = v ?? false),
              title: const Text('Can write notes'),
            ),
            CheckboxListTile(
              value: doctorAlerts,
              onChanged: (v) => setState(() => doctorAlerts = v ?? false),
              title: const Text('Can receive alerts'),
            ),
            CheckboxListTile(
              value: doctorCarePlan,
              onChanged: (v) => setState(() => doctorCarePlan = v ?? false),
              title: const Text('Can manage care plan'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendDoctorRequest,
                child: const Text('Send Doctor Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteParentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: _parentIdController,
              decoration: const InputDecoration(
                labelText: 'Family Member ID / Invite Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _parentLabelController,
              decoration: const InputDecoration(
                labelText: 'Relationship Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _parentNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes on relationship',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: parentVitals,
              onChanged: (v) => setState(() => parentVitals = v ?? false),
              title: const Text('Can view vitals'),
            ),
            CheckboxListTile(
              value: parentReports,
              onChanged: (v) => setState(() => parentReports = v ?? false),
              title: const Text('Can view reports'),
            ),
            CheckboxListTile(
              value: parentMedications,
              onChanged: (v) => setState(() => parentMedications = v ?? false),
              title: const Text('Can view medications'),
            ),
            CheckboxListTile(
              value: parentAlerts,
              onChanged: (v) => setState(() => parentAlerts = v ?? false),
              title: const Text('Can receive alerts'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendParentRequest,
                child: const Text('Send Family Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(CareLink link) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: link.linkedUserRole == LinkUserRole.doctor
                      ? Colors.blue.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  child: Icon(
                    link.linkedUserRole == LinkUserRole.doctor
                        ? Icons.medical_services
                        : Icons.family_restroom,
                    color: link.linkedUserRole == LinkUserRole.doctor
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.relationshipLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('User ID: ${link.linkedUserId}'),
                      if (link.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(link.notes, style: const TextStyle(color: Colors.grey)),
                      ]
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(link.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(link.status),
                    style: TextStyle(
                      color: _statusColor(link.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (link.isPrimary)
                  _chip('Primary Doctor', Colors.green),
                if (link.canViewVitals)
                  _chip('Vitals', Colors.blue),
                if (link.canViewReports)
                  _chip('Reports', Colors.purple),
                if (link.canViewMedications)
                  _chip('Medications', Colors.teal),
                if (link.canWriteNotes)
                  _chip('Notes', Colors.indigo),
                if (link.canReceiveAlerts)
                  _chip('Alerts', Colors.red),
                if (link.canManageCarePlan)
                  _chip('Care Plan', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (link.status == LinkStatus.approved &&
                    link.linkedUserRole == LinkUserRole.doctor)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _service.setPrimaryDoctor(
                          patientId: widget.patientId,
                          linkId: link.id,
                        );
                      },
                      child: const Text('Set Primary'),
                    ),
                  ),
                if (link.status == LinkStatus.approved &&
                    link.linkedUserRole == LinkUserRole.doctor)
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditPermissionsDialog(link),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await _service.removeLink(link.id);
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}