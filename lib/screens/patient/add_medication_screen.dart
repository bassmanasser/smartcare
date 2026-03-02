import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final String patientId;
  const AddMedicationScreen({super.key, required this.patientId});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();

  String _frequency = 'Once daily';
  bool _active = true;

  // times per day (default 1 time)
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  int _freqToCount(String freq) {
    switch (freq) {
      case 'Twice daily':
        return 2;
      case 'Three times daily':
        return 3;
      default:
        return 1;
    }
  }

  void _syncTimesWithFrequency() {
    final count = _freqToCount(_frequency);

    if (_times.length == count) return;

    if (_times.length < count) {
      while (_times.length < count) {
        _times.add(const TimeOfDay(hour: 8, minute: 0));
      }
    } else {
      _times = _times.take(count).toList();
    }
    setState(() {});
  }

  Future<void> _pickTime(int idx) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[idx],
    );
    if (picked != null) {
      setState(() {
        _times[idx] = picked;
      });
    }
  }

  // ✅ FIX: save into users/{patientId}/medications
  CollectionReference<Map<String, dynamic>> _medsRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('medications');
  }

  Map<String, dynamic> _timeToMap(TimeOfDay t) => {"h": t.hour, "m": t.minute};

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final doc = await _medsRef().add({
        "patientId": widget.patientId,
        "name": _nameCtrl.text.trim(),
        "dosage": _dosageCtrl.text.trim(),
        "frequency": _frequency,
        "active": _active,
        "reminderEnabled": true,
        "times": _times.map(_timeToMap).toList(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Notification scheduling (لو عندك service شغال)
      try {
        await NotificationService.scheduleMedicationReminders(
          medicationId: doc.id,
          name: _nameCtrl.text.trim(),
          times: _times,
        );
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save medication: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncTimesWithFrequency();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medication"),
        backgroundColor: PETROL_DARK,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Medication name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  labelText: "Dosage",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: "Frequency",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Once daily', child: Text('Once daily')),
                  DropdownMenuItem(value: 'Twice daily', child: Text('Twice daily')),
                  DropdownMenuItem(value: 'Three times daily', child: Text('Three times daily')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _frequency = v;
                  });
                },
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text("Active"),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Times", style: TextStyle(color: Colors.grey[700])),
              ),
              const SizedBox(height: 8),

              ...List.generate(_times.length, (i) {
                final t = _times[i].format(context);
                return Card(
                  child: ListTile(
                    title: Text("Time ${i + 1}"),
                    subtitle: Text(t),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(i),
                  ),
                );
              }),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PETROL,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
