import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../utils/constants.dart';

class StaffScanPatientScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const StaffScanPatientScreen({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<StaffScanPatientScreen> createState() => _StaffScanPatientScreenState();
}

class _StaffScanPatientScreenState extends State<StaffScanPatientScreen> {
  final TextEditingController _patientIdController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  Future<void> _linkPatient(String rawId) async {
    final patientId = rawId.trim();
    if (patientId.isEmpty) return;

    setState(() => _loading = true);

    try {
      final users = FirebaseFirestore.instance.collection('users');

      QuerySnapshot<Map<String, dynamic>> byPatientId = await users
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      DocumentSnapshot<Map<String, dynamic>>? patientDoc;
      String linkedPatientDocId = '';

      if (byPatientId.docs.isNotEmpty) {
        patientDoc = byPatientId.docs.first;
        linkedPatientDocId = patientDoc.id;
      } else {
        final directDoc = await users.doc(patientId).get();
        if (directDoc.exists) {
          patientDoc = directDoc;
          linkedPatientDocId = directDoc.id;
        }
      }

      if (patientDoc == null || !patientDoc.exists) {
        throw Exception('Patient not found');
      }

      final patientData = patientDoc.data() ?? {};
      final patientName =
          (patientData['name'] ?? patientData['fullName'] ?? 'Patient')
              .toString();

      await FirebaseFirestore.instance
          .collection('care_links')
          .doc('${widget.staffId}_$linkedPatientDocId')
          .set({
        'linkedUserRole': 'staff',
        'linkedUserId': widget.staffId,
        'staffId': widget.staffId,
        'staffName': widget.staffName,
        'patientId': linkedPatientDocId,
        'patientName': patientName,
        'status': 'approved',
        'relationshipLabel': 'staff_patient',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await users.doc(linkedPatientDocId).set({
        'staffId': widget.staffId,
        'staffName': widget.staffName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient linked successfully: $patientName')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to link patient: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _StaffQrScannerPage()),
    );

    if (result != null && result.trim().isNotEmpty) {
      _patientIdController.text = result.trim();
      await _linkPatient(result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(
        title: const Text('Scan Patient QR'),
        centerTitle: true,
        backgroundColor: PETROL_DARK,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Scan the patient QR code or enter patient ID manually.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _patientIdController,
            decoration: InputDecoration(
              labelText: 'Patient ID',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _linkPatient(_patientIdController.text),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link_rounded),
                  label: const Text('Link Patient'),
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
    );
  }
}

class _StaffQrScannerPage extends StatefulWidget {
  const _StaffQrScannerPage();

  @override
  State<_StaffQrScannerPage> createState() => _StaffQrScannerPageState();
}

class _StaffQrScannerPageState extends State<_StaffQrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Patient QR'),
        backgroundColor: PETROL_DARK,
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
        ],
      ),
    );
  }
}