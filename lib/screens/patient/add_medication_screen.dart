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
      // add default times
      while (_times.length < count) {
        if (_times.length == 1) {
          _times.add(const TimeOfDay(hour: 20, minute: 0));
        } else if (_times.length == 2) {
          _times.add(const TimeOfDay(hour: 14, minute: 0));
        } else {
          _times.add(const TimeOfDay(hour: 9, minute: 0));
        }
      }
    } else {
      // remove extra times
      _times = _times.take(count).toList();
    }
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final dosage = _dosageCtrl.text.trim();

      // 1) Save to Firestore
      final medsRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('medications');

      final doc = await medsRef.add({
        'name': name,
        'dosage': dosage,
        'frequency': _frequency,
        'active': _active,
        'times': _times.map((t) => {'h': t.hour, 'm': t.minute}).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2) Schedule notifications (if active)
      if (_active) {
        for (final t in _times) {
          final idSeed = 'med_${widget.patientId}_${doc.id}_${t.hour}_${t.minute}';
          final nid = NotificationService.instance.makeId(idSeed);

          await NotificationService.instance.scheduleDaily(
            id: nid,
            title: '💊 Medication Reminder',
            body: 'Time to take $name ($dosage)',
            hour: t.hour,
            minute: t.minute,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication added + reminders scheduled ✅')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        title: const Text('Add Medication'),
        backgroundColor: PETROL_DARK,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medication name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter medication name';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Dosage
              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g., 1 pill / 5ml)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter dosage';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Frequency
              DropdownButtonFormField<String>(
                value: _frequency,
                items: const [
                  DropdownMenuItem(value: 'Once daily', child: Text('Once daily')),
                  DropdownMenuItem(value: 'Twice daily', child: Text('Twice daily')),
                  DropdownMenuItem(value: 'Three times daily', child: Text('Three times daily')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _frequency = v);
                },
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Active
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Active reminders'),
                subtitle: const Text('If OFF → will save medication without notifications'),
              ),

              const SizedBox(height: 8),
              const Text(
                'Reminder times',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Times list
              Column(
                children: List.generate(_times.length, (i) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.alarm, color: PETROL),
                      title: Text('Time ${i + 1}'),
                      subtitle: Text(_fmt(_times[i])),
                      trailing: TextButton(
                        onPressed: () => _pickTime(i),
                        child: const Text('Change'),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PETROL,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
