import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../utils/constants.dart';
import '../../services/medical_report_service.dart';
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
      final meds = await repo.medsOnce(widget.patientId);
      final moods = await repo.moodsOnce(widget.patientId, limit: widget.lastN);

      final bytes = await MedicalReportService.buildPdf(
        patientId: widget.patientId,
        patientName: widget.patientName,
        vitals: vitals,
        alerts: alerts,
        meds: meds,
        moods: moods,
      );

      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
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
                    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => _pdfBytes!);
                  },
                ),
              ),
            ),
    );
  }
}

/// =======================================================
/// PDF Builder Service
/// (موجود هنا عشان report_screen يستخدمه بسهولة)
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
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SMARTCARE - Medical Report',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Patient: $name', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Patient ID: $id', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.Text('$dd/$mm/$yyyy  $hh:$mi',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String t) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        t,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _summaryLatest(List<Map<String, dynamic>> vitals) {
    if (vitals.isEmpty) {
      return pw.Text('No vitals available.');
    }
    final v = vitals.first;

    final hr = toIntSafe(v['hr']) ?? toIntSafe(v['heartRate']);
    final spo2 = toIntSafe(v['spo2']);
    final temp = toDoubleSafe(v['temperature']) ?? toDoubleSafe(v['tempC']);
    final glucoseAi = toDoubleSafe(v['Predicted Glucose AI']) ??
        toDoubleSafe(v['predicted_glucose_ai']) ??
        toDoubleSafe(v['glucose_ai']);
    final glucose = toDoubleSafe(v['glucose']) ?? glucoseAi;
    final fall = (v['fallFlag'] == true) || (v['fall_detected'] == true);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Wrap(
        spacing: 18,
        runSpacing: 6,
        children: [
          pw.Text('HR: ${hr ?? '-'} bpm'),
          pw.Text('SpO₂: ${spo2 ?? '-'} %'),
          pw.Text('Temp: ${temp != null ? temp.toStringAsFixed(1) : '-'} °C'),
          pw.Text('Glucose(AI): ${glucose != null ? glucose.toStringAsFixed(0) : '-'} mg/dL'),
          pw.Text('Fall: ${fall ? 'YES' : 'NO'}'),
        ],
      ),
    );
  }

  static pw.Widget _vitalsTable(List<Map<String, dynamic>> vitals) {
    if (vitals.isEmpty) return pw.Text('No vitals.');

    final rows = <List<String>>[];
    for (final v in vitals) {
      final ts = tsToDate(v['timestamp']) ?? tsToDate(v['createdAt']);
      final t = ts != null ? _fmt(ts) : '-';

      final hr = toIntSafe(v['hr']) ?? toIntSafe(v['heartRate']);
      final spo2 = toIntSafe(v['spo2']);
      final temp = toDoubleSafe(v['temperature']) ?? toDoubleSafe(v['tempC']);

      final glucoseAi = toDoubleSafe(v['Predicted Glucose AI']) ??
          toDoubleSafe(v['predicted_glucose_ai']) ??
          toDoubleSafe(v['glucose_ai']);
      final glucose = toDoubleSafe(v['glucose']) ?? glucoseAi;

      final fall = (v['fallFlag'] == true) || (v['fall_detected'] == true);

      rows.add([
        t,
        hr?.toString() ?? '-',
        spo2?.toString() ?? '-',
        temp != null ? temp.toStringAsFixed(1) : '-',
        glucose != null ? glucose.toStringAsFixed(0) : '-',
        fall ? 'YES' : 'NO',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Time', 'HR', 'SpO₂', 'Temp', 'Glucose(AI)', 'Fall'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.0),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(1.0),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.6),
        5: const pw.FlexColumnWidth(1.0),
      },
    );
  }

  static pw.Widget _alertsTable(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) return pw.Text('No alerts.');

    final rows = <List<String>>[];
    for (final a in alerts) {
      final ts = tsToDate(a['timestamp']) ?? tsToDate(a['createdAt']);
      rows.add([
        ts != null ? _fmt(ts) : '-',
        strSafe(a['severity'], fallback: '-'),
        strSafe(a['message'], fallback: '-'),
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Time', 'Severity', 'Message'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(3.0),
      },
    );
  }

  static pw.Widget _medsTable(List<Map<String, dynamic>> meds) {
    if (meds.isEmpty) return pw.Text('No medications.');

    final rows = <List<String>>[];
    for (final m in meds) {
      rows.add([
        strSafe(m['name'], fallback: '-'),
        strSafe(m['dosage'], fallback: '-'),
        strSafe(m['frequency'], fallback: '-'),
        (m['active'] == true) ? 'Active' : 'Inactive',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Medication', 'Dosage', 'Frequency', 'Status'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400),
    );
  }

  static pw.Widget _moodsTable(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) return pw.Text('No mood records.');

    final rows = <List<String>>[];
    for (final m in moods) {
      final ts = tsToDate(m['timestamp']) ?? tsToDate(m['createdAt']);
      rows.add([
        ts != null ? _fmt(ts) : '-',
        strSafe(m['mood'], fallback: '-'),
        strSafe(m['note'], fallback: ''),
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: const ['Time', 'Mood', 'Note'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(2.8),
      },
    );
  }

  static String _fmt(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$mi';
  }
}
