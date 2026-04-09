import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smartcare/models/patient.dart';
import 'package:smartcare/providers/app_state.dart';

class PdfReportService {
  static Future<Uint8List> generateReportData({
    required String patientName,
    required List<Map<String, dynamic>> vitalsMap,
    required List<Map<String, dynamic>> alertsMap,
    required List<Map<String, dynamic>> medsMap,
    required List<Map<String, dynamic>> moodsMap,
  }) async {
    final pdf = pw.Document();

    final vitalsRows = vitalsMap.map((m) {
      return [
        _fmtDate(m['timestamp'] ?? m['createdAt'] ?? m['t']),
        (m['hr'] ?? '--').toString(),
        (m['spo2'] ?? '--').toString(),
        '${m['sys'] ?? '--'}/${m['dia'] ?? '--'}',
        (m['glucose'] ?? '--').toString(),
      ];
    }).toList();

    final moodsRows = moodsMap.map((m) {
      return [
        _fmtDate(m['date'] ?? m['createdAt']),
        (m['mood'] ?? '--').toString(),
        (m['note'] ?? '--').toString(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'SmartCare Medical Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Patient: $patientName'),
          pw.Text('Generated: ${_fmtDate(DateTime.now())}'),
          pw.SizedBox(height: 18),
          pw.Divider(),

          pw.SizedBox(height: 14),
          _sectionTitle('1. Vitals History'),
          pw.SizedBox(height: 8),
          vitalsRows.isEmpty
              ? pw.Text('No vitals data available.')
              : pw.TableHelper.fromTextArray(
                  headers: const [
                    'Date/Time',
                    'HR (bpm)',
                    'SpO2 (%)',
                    'BP (mmHg)',
                    'Glu (mg/dL)',
                  ],
                  data: vitalsRows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                ),

          pw.SizedBox(height: 18),
          _sectionTitle('2. Recent Alerts'),
          pw.SizedBox(height: 8),
          alertsMap.isEmpty
              ? pw.Text('No alerts.')
              : pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: alertsMap.map((a) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Bullet(
                        text:
                            '${(a['message'] ?? 'Alert').toString()}'
                            ' (${(a['severity'] ?? 'normal').toString()})'
                            ' - ${_fmtDate(a['timestamp'] ?? a['createdAt'])}',
                      ),
                    );
                  }).toList(),
                ),

          pw.SizedBox(height: 18),
          _sectionTitle('3. Medications'),
          pw.SizedBox(height: 8),
          medsMap.isEmpty
              ? pw.Text('No medications listed.')
              : pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: medsMap.map((m) {
                    final name = (m['name'] ?? '--').toString();
                    final dosage = (m['dosage'] ?? '--').toString();
                    final frequency = (m['frequency'] ?? '--').toString();
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Bullet(text: '$name - $dosage ($frequency)'),
                    );
                  }).toList(),
                ),

          pw.SizedBox(height: 18),
          _sectionTitle('4. Mood Records'),
          pw.SizedBox(height: 8),
          moodsRows.isEmpty
              ? pw.Text('No mood records available.')
              : pw.TableHelper.fromTextArray(
                  headers: const ['Date/Time', 'Mood', 'Note'],
                  data: moodsRows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
    );
  }

  static String _fmtDate(dynamic value) {
    if (value == null) return '-';

    DateTime? dateTime;

    if (value is DateTime) {
      dateTime = value;
    } else if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String && value.trim().isNotEmpty) {
      dateTime = DateTime.tryParse(value);
    } else {
      try {
        final dynamic ms = value.millisecondsSinceEpoch;
        if (ms is int) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      } catch (_) {}
    }

    if (dateTime == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static Future<void> generateAndShareReport(
    Patient patient,
    AppState app,
  ) async {
    final vitalsList = await app.getVitalsForPatient(patient.id);

    final bytes = await generateReportData(
      patientName: patient.name,
      vitalsMap: vitalsList.map((v) => v.toJson()).toList(),
      alertsMap: app
          .getAlertsForPatient(patient.id)
          .map((a) => a.toJson())
          .toList(),
      medsMap: app
          .getMedicationsForPatient(patient.id)
          .map((m) => m.toJson())
          .toList(),
      moodsMap: app
          .getMoodsForPatient(patient.id)
          .map((m) => m.toJson())
          .toList(),
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'SmartCare_Report_${patient.name}.pdf',
    );
  }
}
