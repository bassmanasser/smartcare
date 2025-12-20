import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class DoctorNotesScreen extends StatelessWidget {
  final String patientId;
  const DoctorNotesScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    // جلب الملاحظات وعكسها لإظهار الأحدث أولاً
    final notes = app.notesFor(patientId).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Doctor's Notes")),
      body: notes.isEmpty
          ? const Center(
              child: Text("No notes from your doctor yet."),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const Icon(Icons.note_alt_outlined),
                    title:
                        Text(note.text, style: const TextStyle(fontSize: 16)),
                    subtitle: Text(
                      // تنسيق التاريخ والوقت
                      DateFormat.yMd().add_jm().format(note.date.toLocal()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }
}