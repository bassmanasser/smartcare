import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  final List myPatients;

  const DoctorAppointmentsScreen({super.key, required this.myPatients});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("جدول المواعيد"), backgroundColor: PETROL_DARK),
      body: myPatients.isEmpty
          ? const Center(child: Text("لا توجد مواعيد محجوزة"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myPatients.length,
              itemBuilder: (context, index) {
                final p = myPatients[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(backgroundColor: PETROL.withOpacity(0.1), child: const Icon(Icons.alarm, color: PETROL)),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("التاريخ: 2026-02-25\nالوقت: ${index + 9}:00 AM"),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text("تعديل", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}