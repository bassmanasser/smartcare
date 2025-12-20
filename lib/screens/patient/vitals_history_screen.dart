import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/vitals_service.dart';

class VitalsHistoryScreen extends StatelessWidget {
  final String patientId;
  const VitalsHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final service = VitalsService();

    return Scaffold(
      appBar: AppBar(title: const Text('Vitals History'), backgroundColor: PETROL_DARK),
      body: StreamBuilder<List<VitalsDoc>>(
        stream: service.vitalsStream(patientId, limit: 50),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('No vitals recorded.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final v = list[i];
              final date = '${v.timestamp.day.toString().padLeft(2, '0')}/${v.timestamp.month.toString().padLeft(2, '0')}';
              final time = '${v.timestamp.hour.toString().padLeft(2, '0')}:${v.timestamp.minute.toString().padLeft(2, '0')}';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.monitor_heart, color: PETROL),
                  title: Text('HR: ${v.hr} bpm • SpO₂: ${v.spo2}%'),
                  subtitle: Text('BP: ${v.sys}/${v.dia} • Glu: ${v.glucose.toStringAsFixed(0)} • Temp: ${v.temperature.toStringAsFixed(1)}\n$date • $time'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
