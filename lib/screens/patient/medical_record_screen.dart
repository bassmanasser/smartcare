import 'package:flutter/material.dart';
import '../../models/patient.dart';

class MedicalRecordScreen extends StatelessWidget {
  final Patient patient;
  const MedicalRecordScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("السجل الطبي الرقمي")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard("المعلومات الأساسية", Icons.person, [
              "الاسم: ${patient.name}",
              "فصيلة الدم: ${patient.bloodType ?? 'غير محددة'}",
              "الجنس: ${patient.gender}",
            ]),
            const SizedBox(height: 15),
            _buildListSection("الحساسية", Icons.warning, patient.allergies, Colors.red),
            const SizedBox(height: 15),
            _buildListSection("الأمراض المزمنة", Icons.history, patient.chronicDiseases, Colors.orange),
            const SizedBox(height: 15),
            _buildListSection("الأدوية الحالية", Icons.medication, patient.currentMedications, Colors.green),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.cloud_upload),
              label: const Text("رفع صور الأشعة والتحاليل"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<String> info) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(info.join("\n")),
      ),
    );
  }

  Widget _buildListSection(String title, IconData icon, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        items.isEmpty 
          ? const Text("لا يوجد بيانات مسجلة")
          : Wrap(spacing: 8, children: items.map((e) => Chip(label: Text(e), backgroundColor: color.withOpacity(0.1))).toList()),
      ],
    );
  }
}