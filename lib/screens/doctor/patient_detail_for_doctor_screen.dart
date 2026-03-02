import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/doctor_note.dart';
import '../../models/patient.dart';
import '../../providers/app_state.dart';
import '../../services/pdf_report_service.dart';

class PatientDetailForDoctorScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailForDoctorScreen({super.key, required this.patient});

  @override
  State<PatientDetailForDoctorScreen> createState() => _PatientDetailForDoctorScreenState();
}

class _PatientDetailForDoctorScreenState extends State<PatientDetailForDoctorScreen> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    // ✅ FIX: ممكن ترجع null
    final notes = (app.getNotesForPatient(widget.patient.id) ?? []).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // ⚠️ لو pdf_report_service بيقرأ من collection عامة بدون صلاحيات → هيطلع permission denied
              PdfReportService.generateAndShareReport(widget.patient, app);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Export Medical Report"),
          ),

          const SizedBox(height: 20),

          const Text("Add Doctor Note:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter clinical notes here...',
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {
              final text = _noteCtrl.text.trim();
              if (text.isEmpty) return;

              final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

              final newNote = DoctorNote(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                patientId: widget.patient.id,
                text: text,
                date: DateTime.now(),
                doctorId: doctorId,
              );

              app.addDoctorNote(newNote);

              _noteCtrl.clear();
              FocusScope.of(context).unfocus();
            },
            child: const Text("Save Note"),
          ),

          const Divider(height: 40),

          if (notes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No notes yet."),
              ),
            )
          else
            ...notes.map(
              (n) => Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.note, color: Colors.blueGrey),
                  title: Text(n.text),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy hh:mm a').format(n.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
