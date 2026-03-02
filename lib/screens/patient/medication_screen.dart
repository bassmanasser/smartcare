import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../utils/constants.dart';

class MedicationScreen extends StatefulWidget {
  final String patientId;
  const MedicationScreen({super.key, required this.patientId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  Map<String, dynamic> _timeToMap(TimeOfDay t) => {"h": t.hour, "m": t.minute};

  TimeOfDay? _mapToTime(dynamic x) {
    if (x is Map) {
      final h = x['h'];
      final m = x['m'];
      if (h is int && m is int) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _medsRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('medications');
  }

  Future<void> _toggleReminder(String medId, bool value) async {
    await _medsRef().doc(medId).update({'reminderEnabled': value});
  }

  Future<void> _addMedicationDialog() async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    TimeOfDay? selectedTime;
    bool enableReminder = false;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Medication Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(labelText: 'Dosage (e.g. 1 pill)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: freqCtrl,
                decoration: const InputDecoration(labelText: 'Frequency (e.g. 2 times/day)'),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setInner) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable reminder'),
                        value: enableReminder,
                        onChanged: (v) {
                          setInner(() {
                            enableReminder = v;
                            if (!v) selectedTime = null;
                          });
                        },
                      ),
                      if (enableReminder)
                        TextButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null) {
                              setInner(() {
                                selectedTime = t;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            selectedTime == null ? 'Select time' : selectedTime!.format(context),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || dosageCtrl.text.trim().isEmpty) return;

              Navigator.pop(c, {
                "name": nameCtrl.text.trim(),
                "dosage": dosageCtrl.text.trim(),
                "frequency": freqCtrl.text.trim(),
                "reminderEnabled": enableReminder && selectedTime != null,
                "reminderTime": selectedTime == null ? null : _timeToMap(selectedTime!),
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _medsRef().add({
        "patientId": widget.patientId,
        "name": result["name"],
        "dosage": result["dosage"],
        "frequency": result["frequency"],
        "active": true,
        "reminderEnabled": result["reminderEnabled"] ?? false,
        "reminderTime": result["reminderTime"],
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  Medication _docToMedication(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Medication(
      id: doc.id,
      patientId: (d['patientId'] ?? widget.patientId).toString(),
      name: (d['name'] ?? '').toString(),
      dosage: (d['dosage'] ?? '').toString(),
      frequency: (d['frequency'] ?? '').toString(),
      active: d['active'] == true,
      reminderEnabled: d['reminderEnabled'] == true,
      reminderTime: _mapToTime(d['reminderTime']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        backgroundColor: PETROL_DARK,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedicationDialog,
        backgroundColor: PETROL,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _medsRef().snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No medications added yet.'));
          }

          // ✅ FIX: sort على List مش null
          final meds = snap.data!.docs.map(_docToMedication).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: meds.length,
            itemBuilder: (c, i) {
              final med = meds[i];
              final timeText = med.reminderTime != null
                  ? med.reminderTime!.format(context)
                  : 'No time set';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: SwitchListTile(
                  title: Text(
                    med.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${med.dosage} • ${med.frequency}\nReminder: $timeText'),
                  isThreeLine: true,
                  value: med.reminderEnabled,
                  onChanged: (value) async {
                    await _toggleReminder(med.id, value);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
