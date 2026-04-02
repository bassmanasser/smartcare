import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../utils/constants.dart';

class PatientQrSimpleScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PatientQrSimpleScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'type': 'patient_qr',
      'patientId': patientId,
      'patientName': patientName,
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('My QR Code'),
        centerTitle: true,
        backgroundColor: PETROL_DARK,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_rounded,
                  size: 44,
                  color: PETROL_DARK,
                ),
                const SizedBox(height: 12),
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: PETROL_DARK,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  'Patient ID: $patientId',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Let the doctor scan this QR code to link your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    height: 1.4,
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