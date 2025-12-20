import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medication.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';

class MedicationScreen extends StatefulWidget {
  final String patientId;
  const MedicationScreen({super.key, required this.patientId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  Future<void> _addMedicationDialog() async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    TimeOfDay? selectedTime;
    bool enableReminder = false;

    final result = await showDialog<Medication?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Medication Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dosageCtrl,
                decoration:
                    const InputDecoration(labelText: 'Dosage (e.g. 1 pill)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: freqCtrl,
                decoration: const InputDecoration(
                    labelText: 'Frequency (e.g. 2 times/day)'),
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
                            selectedTime == null
                                ? 'Select time'
                                : selectedTime!.format(context),
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
              if (nameCtrl.text.trim().isEmpty ||
                  dosageCtrl.text.trim().isEmpty) {
                return;
              }

              final med = Medication(
                id: '',
                patientId: widget.patientId,
                name: nameCtrl.text.trim(),
                dosage: dosageCtrl.text.trim(),
                frequency: freqCtrl.text.trim(),
                active: true,
                reminderTime: enableReminder ? selectedTime : null,
                reminderEnabled:
                    enableReminder && selectedTime != null,
              );
              Navigator.pop(c, med);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final app = Provider.of<AppState>(context, listen: false);
      await app.addMedication(result, widget.patientId as Medication);
    }
  }

  Future<void> _toggleReminder(Medication med, bool value) async {
    await FirebaseFirestore.instance
        .collection('medications')
        .doc(med.id)
        .update({'reminderEnabled': value});
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final meds = app.getMedicationsForPatient(widget.patientId)
      ..sort((a, b) => a.name.compareTo(b.name));

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
      body: meds.isEmpty
          ? const Center(child: Text('No medications added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: meds.length,
              itemBuilder: (c, i) {
                final med = meds[i];
                final timeText = med.reminderTime != null
                    ? med.reminderTime!.format(context)
                    : 'No time set';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 8),
                  child: SwitchListTile(
                    title: Text(
                      med.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${med.dosage} • ${med.frequency}\nReminder: $timeText',
                    ),
                    isThreeLine: true,
                    value: med.reminderEnabled,
                    onChanged: (newValue) {
                      _toggleReminder(med, newValue);
                    },
                  ),
                );
              },
            ),
    );
  }
}
