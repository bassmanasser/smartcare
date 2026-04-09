import 'package:flutter/material.dart';

import '../../models/doctor.dart';
import '../../utils/constants.dart';
import 'doctor_home_screen.dart';
import 'patient_detail_for_doctor_screen.dart';

class AssignedCasesScreen extends StatelessWidget {
  final Doctor doctor;
  final List<DoctorQueueItem> queue;

  const AssignedCasesScreen({
    super.key,
    required this.doctor,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    final activeQueue = [...queue]..sort((a, b) => b.sortValue.compareTo(a.sortValue));

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(
        title: const Text('Assigned Cases'),
        centerTitle: true,
        backgroundColor: PETROL_DARK,
      ),
      body: activeQueue.isEmpty
          ? const Center(
              child: Text(
                'No assigned cases yet.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: activeQueue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = activeQueue[index];
                final urgency = urgencyColor(item.urgency);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PatientDetailForDoctorScreen(patient: item.patient),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: urgency.withOpacity(0.12),
                                child: Icon(
                                  Icons.local_hospital_rounded,
                                  color: urgency,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Specialty: ${pretty(item.specialty)}',
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: urgency.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  pretty(item.urgency),
                                  style: TextStyle(
                                    color: urgency,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniMetric(
                                  label: 'Risk',
                                  value: pretty(item.riskLevel),
                                ),
                              ),
                              Expanded(
                                child: _MiniMetric(
                                  label: 'Action',
                                  value: pretty(item.action),
                                ),
                              ),
                              Expanded(
                                child: _MiniMetric(
                                  label: 'Alerts',
                                  value: '${item.alertCount}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xffF6F8FB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item.explanation,
                              style: const TextStyle(height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: PETROL_DARK,
          ),
        ),
      ],
    );
  }
}