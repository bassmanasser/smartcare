import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _patientData;
  String? _patientDocId;

  String _priority = 'normal';
  bool _searching = false;
  bool _saving = false;

  @override
  void dispose() {
    _patientIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _findPatientById(String rawId) async {
    final id = rawId.trim();
    if (id.isEmpty) return;

    setState(() {
      _searching = true;
      _patientData = null;
      _patientDocId = null;
    });

    try {
      final users = FirebaseFirestore.instance.collection('users');

      QuerySnapshot<Map<String, dynamic>> byPatientId = await users
          .where('patientId', isEqualTo: id)
          .limit(1)
          .get();

      if (byPatientId.docs.isNotEmpty) {
        final doc = byPatientId.docs.first;
        setState(() {
          _patientDocId = doc.id;
          _patientData = doc.data();
        });
        return;
      }

      final byDocId = await users.doc(id).get();
      if (byDocId.exists) {
        final data = byDocId.data();
        if (data != null && (data['role'] ?? '').toString() == 'patient') {
          setState(() {
            _patientDocId = byDocId.id;
            _patientData = data;
          });
          return;
        }
      }

      final byUid = await users.where('uid', isEqualTo: id).limit(1).get();
      if (byUid.docs.isNotEmpty) {
        final doc = byUid.docs.first;
        final data = doc.data();
        if ((data['role'] ?? '').toString() == 'patient') {
          setState(() {
            _patientDocId = doc.id;
            _patientData = data;
          });
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient found with this ID/QR')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search patient: $e')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const _QrScannerPage(),
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      _patientIdController.text = result.trim();
      await _findPatientById(result.trim());
    }
  }

  Future<void> _admitPatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patientDocId == null || _patientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or enter a valid patient ID first')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final patientName = (_patientData?['name'] ??
              _patientData?['fullName'] ??
              'Unknown Patient')
          .toString();

      final now = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('users').doc(_patientDocId).set({
        'institutionId': widget.institutionId,
        'institutionName': widget.institutionName,
        'arrivalDayKey': _todayKey(),
        'admittedAt': now,
        'admissionSource': 'hospital_admin_scan_or_id',
        'updatedAt': now,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('dispatch_cases').add({
        'patientId': _patientDocId,
        'patientName': patientName,
        'institutionId': widget.institutionId,
        'institutionName': widget.institutionName,
        'priority': _priority,
        'severity': _priority,
        'status': 'waiting',
        'source': 'hospital_qr_or_manual_id',
        'createdAt': now,
        'notes': _notesController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient admitted successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to admit patient: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _readPatientName() {
    return (_patientData?['name'] ?? _patientData?['fullName'] ?? '-').toString();
  }

  String _readPatientPhone() {
    return (_patientData?['phone'] ?? '-').toString();
  }

  String _readPatientAge() {
    return (_patientData?['age'] ?? '-').toString();
  }

  String _readPatientGender() {
    return (_patientData?['gender'] ?? '-').toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admit Patient'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scan QR or Enter Patient ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find the patient first, then complete the hospital admission.',
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
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _patientIdController,
                      decoration: InputDecoration(
                        labelText: 'Patient ID',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _searching
                                ? null
                                : () => _findPatientById(_patientIdController.text),
                            icon: _searching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search_rounded),
                            label: const Text('Find Patient'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _scanQr,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Scan QR'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_patientData != null)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: colorScheme.primary.withOpacity(0.10),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _readPatientName(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(label: 'Patient Doc ID', value: _patientDocId ?? '-'),
                      _InfoRow(label: 'Phone', value: _readPatientPhone()),
                      _InfoRow(label: 'Age', value: _readPatientAge()),
                      _InfoRow(
                        label: 'Gender',
                        value: _readPatientGender(),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: InputDecoration(
                labelText: 'Priority',
                prefixIcon: const Icon(Icons.priority_high_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
              ],
              onChanged: (value) => setState(() => _priority = value ?? 'normal'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Admission Notes',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.notes_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _admitPatient,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_saving ? 'Admitting...' : 'Admit Patient'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.72),
                ),
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

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Patient QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final codes = capture.barcodes;
              if (codes.isEmpty) return;

              final value = codes.first.rawValue ?? '';
              if (value.trim().isEmpty) return;

              _handled = true;
              Navigator.of(context).pop(value.trim());
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Card(
              color: Colors.black.withOpacity(0.60),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Place the patient QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}