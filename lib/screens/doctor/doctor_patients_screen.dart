import 'package:flutter/material.dart';
import 'patient_detail_for_doctor_screen.dart';

class DoctorPatientsScreen extends StatelessWidget {
  final List myPatients;

  const DoctorPatientsScreen({
    super.key,
    required this.myPatients,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مرضاي"),
        centerTitle: true,
      ),
      body: myPatients.isEmpty
          ? const Center(
              child: Text(
                "لا يوجد مرضى مرتبطين بهذا الدكتور",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myPatients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final patient = myPatients[index];

                final patientName =
                    (patient.name?.toString().trim().isNotEmpty ?? false)
                        ? patient.name.toString()
                        : "Unnamed Patient";

                final patientEmail =
                    (patient.email?.toString().trim().isNotEmpty ?? false)
                        ? patient.email.toString()
                        : "No email";

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PatientDetailForDoctorScreen(patient: patient),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                patientEmail,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}