import 'dart:typed_data';
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

    final vitals = vitalsMap.map((m) {
      return [
        _fmtDate(m['timestamp'] ?? m['createdAt']),
        m['hr']?.toString() ?? '-',
        m['spo2']?.toString() ?? '-',
        '${m['sys'] ?? '-'}/${m['dia'] ?? '-'}',
        m['glucose']?.toString() ?? '-',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Weekly Medical Report')),
          pw.Paragraph(text: 'Patient: $patientName'),
          pw.Paragraph(text: 'Generated: ${_fmtDate(DateTime.now())}'),
          pw.Divider(),
          pw.SizedBox(height: 20),
          pw.Text('1. Vitals History',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 10),
          vitals.isEmpty
              ? pw.Text("No data available.")
              : pw.Table.fromTextArray(
                  headers: ['Date/Time', 'HR (bpm)', 'SpO2 (%)', 'BP (mmHg)', 'Glu (mg/dL)'],
                  data: vitals,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.center,
                ),
          pw.SizedBox(height: 20),
          pw.Text('2. Recent Alerts',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 5),
          if (alertsMap.isEmpty)
            pw.Text("No alerts.")
          else
            ...alertsMap.map((a) => pw.Bullet(
                text:
                    "${a['message']} (${a['severity']}) - ${_fmtDate(a['timestamp'] ?? a['createdAt'])}")),
          pw.SizedBox(height: 20),
          pw.Text('3. Medications',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 5),
          if (medsMap.isEmpty)
            pw.Text("No medications listed.")
          else
            ...medsMap.map((m) =>
                pw.Bullet(text: "${m['name']} - ${m['dosage']} (${m['frequency']})")),
        ],
      ),
    );

    return pdf.save();
  }

  static String _fmtDate(dynamic ts) {
    if (ts == null) return '-';
    DateTime d;

    if (ts is DateTime) {
      d = ts;
    } else if (ts is int) {
      d = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is dynamic && ts.toString().contains('Timestamp')) {
      // Firestore Timestamp (best-effort بدون import cloud_firestore هنا)
      try {
        final ms = ts.millisecondsSinceEpoch as int;
        d = DateTime.fromMillisecondsSinceEpoch(ms);
      } catch (_) {
        return '-';
      }
    } else {
      return '-';
    }

    return DateFormat('MM/dd HH:mm').format(d);
  }

  // ✅ كانت فاضية — دلوقتي شغالة (بدون تغيير UI)
  static Future<void> generateAndShareReport(Patient patient, AppState app) async {
    final vitalsMap = app.getVitalsForPatient(patient.id)?.map((v) => v.toMap()).toList() ?? [];
    final alertsMap = app.getAlertsForPatient(patient.id)?.map((a) => a.toMap()).toList() ?? [];
    final medsMap = app.getMedicationsForPatient(patient.id)?.map((m) => m.toMap()).toList() ?? [];
    final moodsMap = app.getMoodsForPatient(patient.id)?.map((m) => m.toMap()).toList() ?? [];

    final bytes = await generateReportData(
      patientName: patient.name,
      vitalsMap: vitalsMap,
      alertsMap: alertsMap,
      medsMap: medsMap,
      moodsMap: moodsMap,
    );

    await Printing.sharePdf(bytes: bytes, filename: "SmartCare_Report_${patient.name}.pdf");
  }
}
