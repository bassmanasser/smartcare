import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartcare/models/doctor_note.dart';
import '../../models/patient.dart';
import '../../providers/app_state.dart';
import '../../services/medical_report_service.dart';

class PatientDetailForDoctorScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailForDoctorScreen({super.key, required this.patient});

  @override
  State<PatientDetailForDoctorScreen> createState() => _PatientDetailForDoctorScreenState();
}

class _PatientDetailForDoctorScreenState extends State<PatientDetailForDoctorScreen> {
  final _noteCtrl = TextEditingController();
  
  get ReportService => null;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final notes = app.notesFor(widget.patient.id).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: () => ReportService.generateAndShareReport(widget.patient, app),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Export Medical Report"),
          ),
          const SizedBox(height: 20),
          const Text("Add Doctor Note:", style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _noteCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
          ElevatedButton(
            onPressed: () {
              if (_noteCtrl.text.isNotEmpty) {
                app.addDoctorNote(widget.patient.id as DoctorNote, _noteCtrl.text);
                _noteCtrl.clear();
              }
            },
            child: const Text("Save Note"),
          ),
          const Divider(),
          ...notes.map((n) => Card(
                child: ListTile(
                  title: Text(n.text),
                  subtitle: Text(DateFormat.yMd().add_jm().format(n.date)),
                ),
              )),
        ],
      ),
    );
  }
}