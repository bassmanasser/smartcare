import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../utils/constants.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ReportScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final int lastN; // how many records to include

  const ReportScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.lastN = 40,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final repo = PatientDataRepository();
  bool _loading = true;
  Uint8List? _pdfBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buildPdf();
  }

  Future<void> _buildPdf() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final vitals = await repo.vitalsOnce(widget.patientId, limit: widget.lastN);
      final alerts = await repo.alertsOnce(widget.patientId, limit: widget.lastN);
      final meds = await repo.medsOnce(widget.patientId, limit: widget.lastN);
      final moods = await repo.moodsOnce(widget.patientId, limit: widget.lastN);

      final bytes = await MedicalReportService.buildPdf(
        patientId: widget.patientId,
        patientName: widget.patientName,
        vitals: vitals,
        alerts: alerts,
        meds: meds,
        moods: moods,
      );

      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Report (PDF)'),
        backgroundColor: PETROL_DARK,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buildPdf,
          ),
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                await Printing.sharePdf(
                  bytes: _pdfBytes!,
                  filename: 'SmartCare_Report_${widget.patientName}.pdf',
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : PdfPreview(
                  build: (format) async => _pdfBytes!,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                ),
      bottomNavigationBar: (_pdfBytes == null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PETROL,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Print / Save as PDF', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async => _pdfBytes!,
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// =======================================================
/// Firestore Repository (FIX permission-denied)
/// Reads ONLY from users/{uid}/subcollections
/// =======================================================
class PatientDataRepository {
  CollectionReference<Map<String, dynamic>> _sub(String uid, String name) {
    return FirebaseFirestore.instance.collection('users').doc(uid).collection(name);
  }

  Future<List<Map<String, dynamic>>> _latest(String uid, String col, int limit) async {
    // if createdAt exists, use it, else fallback to timestamp
    final q = await _sub(uid, col).limit(limit).get();
    final out = <Map<String, dynamic>>[];
    for (final d in q.docs) {
      out.add({"id": d.id, ...d.data()});
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> vitalsOnce(String uid, {int limit = 40}) async {
    return _latest(uid, 'vitals', limit);
  }

  Future<List<Map<String, dynamic>>> alertsOnce(String uid, {int limit = 40}) async {
    return _latest(uid, 'alerts', limit);
  }

  Future<List<Map<String, dynamic>>> medsOnce(String uid, {int limit = 40}) async {
    return _latest(uid, 'medications', limit);
  }

  Future<List<Map<String, dynamic>>> moodsOnce(String uid, {int limit = 40}) async {
    return _latest(uid, 'moods', limit);
  }
}

/// =======================================================
/// PDF Builder Service (unchanged UI output)
/// =======================================================
class MedicalReportService {
  static Future<Uint8List> buildPdf({
    required String patientId,
    required String patientName,
    required List<Map<String, dynamic>> vitals,
    required List<Map<String, dynamic>> alerts,
    required List<Map<String, dynamic>> meds,
    required List<Map<String, dynamic>> moods,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) {
          return [
            _header(patientName, patientId),
            pw.SizedBox(height: 12),

            _sectionTitle('Summary (Latest)'),
            _summaryLatest(vitals),

            pw.SizedBox(height: 10),
            _sectionTitle('Vitals (Last ${vitals.length})'),
            _vitalsTable(vitals),

            pw.SizedBox(height: 10),
            _sectionTitle('Alerts (Last ${alerts.length})'),
            _alertsTable(alerts),

            pw.SizedBox(height: 10),
            _sectionTitle('Medications'),
            _medsTable(meds),

            pw.SizedBox(height: 10),
            _sectionTitle('Mood Records'),
            _moodsTable(moods),

            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Text(
              'Generated by SmartCare',
              style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(String name, String id) {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    final hh = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('SMARTCARE - Medical Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Patient: $name'),
          pw.Text('Patient ID: $id'),
          pw.Text('Generated: $dd/$mm/$yyyy  $hh:$mi'),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String t) =>
      pw.Text(t, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold));

  static pw.Widget _summaryLatest(List<Map<String, dynamic>> vitals) {
    if (vitals.isEmpty) return pw.Text('No vitals available.');
    final v = vitals.first;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'HR: ${v['hr'] ?? '-'}  |  SpO2: ${v['spo2'] ?? '-'}  |  BP: ${v['sys'] ?? '-'}/${v['dia'] ?? '-'}  |  Glucose: ${v['glucose'] ?? '-'}',
      ),
    );
  }

  static pw.Widget _vitalsTable(List<Map<String, dynamic>> vitals) {
    if (vitals.isEmpty) return pw.Text('No vitals.');
    final rows = vitals.map((v) {
      return [
        (v['timestamp'] ?? v['createdAt'] ?? '').toString(),
        (v['hr'] ?? '-').toString(),
        (v['spo2'] ?? '-').toString(),
        '${v['sys'] ?? '-'}/${v['dia'] ?? '-'}',
        (v['glucose'] ?? '-').toString(),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: ['Time', 'HR', 'SpO2', 'BP', 'Glucose'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    );
  }

  static pw.Widget _alertsTable(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) return pw.Text('No alerts.');
    return pw.Column(
      children: alerts.map((a) {
        return pw.Bullet(
          text: '${a['message'] ?? '-'}  (${a['severity'] ?? '-'})',
        );
      }).toList(),
    );
  }

  static pw.Widget _medsTable(List<Map<String, dynamic>> meds) {
    if (meds.isEmpty) return pw.Text('No medications.');
    return pw.Column(
      children: meds.map((m) {
        return pw.Bullet(
          text: '${m['name'] ?? '-'} - ${m['dosage'] ?? '-'} (${m['frequency'] ?? '-'})',
        );
      }).toList(),
    );
  }

  static pw.Widget _moodsTable(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) return pw.Text('No mood records.');
    return pw.Column(
      children: moods.map((m) {
        return pw.Bullet(text: '${m['mood'] ?? m['value'] ?? '-'}');
      }).toList(),
    );
  }
}
