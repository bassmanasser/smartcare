import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../utils/constants.dart';

class DoctorScanPatientScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorScanPatientScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<DoctorScanPatientScreen> createState() =>
      _DoctorScanPatientScreenState();
}

class _DoctorScanPatientScreenState extends State<DoctorScanPatientScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandling = false;

  Future<void> _handleQr(String rawValue) async {
    if (_isHandling) return;
    _isHandling = true;

    try {
      final decoded = jsonDecode(rawValue);

      if (decoded is! Map || decoded['type'] != 'patient_qr') {
        throw Exception('Invalid patient QR');
      }

      final patientId = (decoded['patientId'] ?? '').toString().trim();
      final patientName = (decoded['patientName'] ?? '').toString().trim();

      if (patientId.isEmpty) {
        throw Exception('Patient ID not found');
      }

      final db = FirebaseFirestore.instance;

      await db.collection('users').doc(patientId).set({
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'linkedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await db.collection('care_links').doc('${widget.doctorId}_$patientId').set({
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'patientId': patientId,
        'patientName': patientName,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            patientName.isEmpty
                ? 'Patient linked successfully'
                : '$patientName linked successfully',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _isHandling = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Scan failed: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        title: const Text(
          'Scan Patient QR',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;

              _handleQr(raw);
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Place the patient QR code inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}