import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/mood_service.dart';

class MoodScreen extends StatelessWidget {
  final String patientId;
  const MoodScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final service = MoodService();

    return Scaffold(
      appBar: AppBar(title: const Text('Mood History'), backgroundColor: PETROL_DARK),
      body: StreamBuilder<List<MoodDoc>>(
        stream: service.moodsStream(patientId, limit: 50),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('No mood records.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final m = list[i];
              final date = '${m.timestamp.day.toString().padLeft(2, '0')}/${m.timestamp.month.toString().padLeft(2, '0')}';
              final time = '${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_emotions, color: PETROL),
                  title: Text(m.mood),
                  subtitle: Text('${m.note ?? ''}\n$date • $time', maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
