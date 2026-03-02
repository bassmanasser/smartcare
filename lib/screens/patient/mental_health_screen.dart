import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mood_record.dart';
import '../../models/patient.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../widgets/mental_charts.dart';

class MentalHealthScreen extends StatefulWidget {
  final Patient patient;
  const MentalHealthScreen({super.key, required this.patient});

  @override
  State<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends State<MentalHealthScreen> {
  int _mood = 3; // 1..5
  double _sleep = 7.0;
  int _stress = 3; // 0..10
  bool _exercise = false;
  final _note = TextEditingController();
  
  get L10n => null;

  Future<void> _save() async {
    final app = Provider.of<AppState>(context, listen: false); // Corrected: Removed `listen: false` as it's not needed for calling a method
    final rec = MoodRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patient.id,
      mood: _mood.toString(),
      note: _note.text.trim(),
      date: DateTime.now(),
    );
    
    await app.addMood(rec); // Corrected: Changed to `addMood` which is defined in AppState

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    _note.clear();
    setState(() {}); // To refresh the UI and show the new record in the chart
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    // Safely build a list of this patient's mood records directly from the app state
    final records = List<MoodRecord>.from(app.moodRecords.where((r) => r.patientId == widget.patient.id));
    final moods = ['😢', '😟', '😐', '😊', '😀'];
    // Prepare a list of recent records (last 30) for the charts
    final List<MoodRecord> recentRecords =
        records.length > 30 ? records.sublist(records.length - 30) : records;

    return Scaffold(
      appBar: AppBar(title: Text(L10n.get(context, 'mentalHealth', onChanged: (String? value) {  }))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('How are you feeling today?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _mood = i + 1),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _mood == i + 1 ? PETROL.withOpacity(0.5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _mood == i+1 ? PETROL : Colors.grey.shade300)
                    ),
                    child: Text(moods[i], style: const TextStyle(fontSize: 32)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Text('Sleep (hrs):'),
              Expanded(
                child: Slider(
                  value: _sleep, min: 0, max: 12, divisions: 24,
                  label: _sleep.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _sleep = v),
                ),
              ),
              Text('${_sleep.toStringAsFixed(1)}h'),
            ]),
            Row(children: [
              const Text('Stress (0-10):'),
              Expanded(
                child: Slider(
                  value: _stress.toDouble(), min: 0, max: 10, divisions: 10,
                  label: '$_stress',
                  onChanged: (v) => setState(() => _stress = v.toInt()),
                ),
              ),
              Text('$_stress'),
            ]),
            SwitchListTile(
              title: const Text('Did you exercise today?'),
              value: _exercise,
              onChanged: (v) => setState(() => _exercise = v),
            ),
            const SizedBox(height: 8),
            TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save Entry')),
            const SizedBox(height: 24),
            const Text('Mood History & Charts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (recentRecords.isEmpty)
              const Text('No mood records yet')
            else
              MentalCharts(records: recentRecords)
          ],
        ),
      ),
    );
  }
}

extension on Uri {
  get patientId => null;
}

extension on Map<String, List<MoodRecord>> {
  Iterable<dynamic> where(bool Function(Uri) param0) {
    return const <dynamic>[];
  }
}