import 'package:flutter/material.dart';
import 'package:smartcare/models/doctor.dart';
import '../../models/care_link.dart';
import '../../services/care_link_service.dart';
import '../../utils/constants.dart';

class DoctorRequestsScreen extends StatelessWidget {
  final String doctorId;
  const DoctorRequestsScreen({super.key, required this.doctorId, required Doctor doctor});

  @override
  Widget build(BuildContext context) {
    final service = CareLinkService();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Incoming Requests'),
        backgroundColor: PETROL_DARK,
      ),
      body: StreamBuilder<List<CareLink>>(
        stream: service.incomingRequestsForUser(doctorId),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.relationshipLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Patient ID: ${req.patientId}'),
                      Text('Requested by: ${req.requestedBy}'),
                      if (req.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Notes: ${req.notes}'),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (req.isPrimary) _chip('Primary', Colors.green),
                          if (req.canViewVitals) _chip('Vitals', Colors.blue),
                          if (req.canViewReports) _chip('Reports', Colors.purple),
                          if (req.canViewMedications)
                            _chip('Medications', Colors.teal),
                          if (req.canWriteNotes) _chip('Notes', Colors.indigo),
                          if (req.canReceiveAlerts) _chip('Alerts', Colors.red),
                          if (req.canManageCarePlan)
                            _chip('Care Plan', Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await service.rejectRequest(req.id);
                              },
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await service.acceptRequest(req.id);
                              },
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}