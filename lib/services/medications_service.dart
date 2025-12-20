import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationDoc {
  final String name;
  final String dosage;
  final String frequency;
  final bool active;

  MedicationDoc({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.active,
  });

  factory MedicationDoc.fromMap(Map<String, dynamic> m) {
    return MedicationDoc(
      name: (m['name'] ?? '') as String,
      dosage: (m['dosage'] ?? '') as String,
      frequency: (m['frequency'] ?? '') as String,
      active: (m['active'] ?? true) as bool,
    );
  }
}

class MedicationsService {
  final _db = FirebaseFirestore.instance;

  Stream<List<MedicationDoc>> medsStream(String patientId) {
    return _db
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .orderBy('name')
        .snapshots()
        .map((qs) => qs.docs.map((d) => MedicationDoc.fromMap(d.data())).toList());
  }
}
