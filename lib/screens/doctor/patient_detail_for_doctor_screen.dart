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

  // نافذة الروشتة الرقمية
  void _showPrescriptionDialog() {
    final medNameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("إضافة روشتة علاجية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: medNameCtrl,
                decoration: const InputDecoration(labelText: "اسم الدواء", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(labelText: "الجرعة (مثال: قرص كل 12 ساعة)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // هنا هنضيف لوجيك حفظ الروشتة في الفايربيس لاحقاً
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم إضافة الدواء للروشتة بنجاح"))
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("حفظ الدواء"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final notes = (app.getNotesForPatient(widget.patient.id) ?? []).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    PdfReportService.generateAndShareReport(widget.patient, app);
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("تصدير تقرير"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _showPrescriptionDialog,
                  icon: const Icon(Icons.medical_services, color: Colors.white),
                  label: const Text("روشتة رقمية", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text("إضافة ملاحظة طبية:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'اكتب ملاحظاتك التشخيصية هنا...',
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
            child: const Text("حفظ الملاحظة"),
          ),

          const Divider(height: 40),

          if (notes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("لا توجد ملاحظات مسجلة بعد."),
              ),
            )
          else
            ...notes.map(
              (n) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.note_alt, color: Colors.blueGrey),
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