import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/parent.dart';
import '../models/vital_sample.dart';
import '../models/doctor_note.dart';
import '../models/medication.dart';
import '../models/alert_item.dart';
import '../models/mood_record.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _listenToRealtimeData();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  // ------------- in-memory maps -------------

  final Map<String, Doctor> doctors = {};
  final Map<String, Patient> patients = {};
  final Map<String, Parent> parents = {};

  final Map<String, List<VitalSample>> vitals = {};
  final Map<String, List<DoctorNote>> doctorNotes = {};
  final Map<String, List<Medication>> medications = {};
  final Map<String, List<AlertItem>> alerts = {};
  final Map<String, List<MoodRecord>> moodRecords = {};

  get patientId => null;

  // ------------- realtime listeners -------------

  void _listenToRealtimeData() {
    // Doctors
    _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .listen((snapshot) {
      doctors.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        doctors[doc.id] = Doctor.fromJson(data);
      }
      notifyListeners();
    });

    // Patients
    _db
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots()
        .listen((snapshot) {
      patients.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        patients[doc.id] = Patient.fromJson(data);
      }
      notifyListeners();
    });

    // Parents
    _db
        .collection('users')
        .where('role', isEqualTo: 'parent')
        .snapshots()
        .listen((snapshot) {
      parents.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        parents[doc.id] = Parent.fromJson(data);
      }
      notifyListeners();
    });

    // Vitals
    _db
        .collection('vitals')
        .orderBy('t', descending: true)
        .limit(500)
        .snapshots()
        .listen((snapshot) {
      vitals.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'] as String;
        data['id'] = doc.id;
        final s = VitalSample.fromJson(data);
        vitals.putIfAbsent(patientId, () => []).add(s);
      }
      notifyListeners();
    });

    // Doctor notes
    _db
        .collection('notes')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      doctorNotes.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pid = data['patientId'] as String;
        data['id'] = doc.id;
        final n = DoctorNote.fromJson(data);
        doctorNotes.putIfAbsent(pid, () => []).add(n);
      }
      notifyListeners();
    });

    // Medications
    _db
        .collection('medications')
        .snapshots()
        .listen((snapshot) {
      medications.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pid = data['patientId'] as String;
        data['id'] = doc.id;
        final m = Medication.fromJson(data);
        medications.putIfAbsent(pid, () => []).add(m);
      }
      notifyListeners();
    });

    // Alerts
    _db
        .collection('alerts')
        .orderBy('t', descending: true)
        .limit(200)
        .snapshots()
        .listen((snapshot) {
      alerts.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pid = data['patientId'] as String;
        data['id'] = doc.id;
        final a = AlertItem.fromJson(data);
        alerts.putIfAbsent(pid, () => []).add(a);
      }
      notifyListeners();
    });

    // Mood
    _db
        .collection('moods')
        .orderBy('t', descending: true)
        .limit(200)
        .snapshots()
        .listen((snapshot) {
      moodRecords.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pid = data['patientId'] as String;
        data['id'] = doc.id;
        final m = MoodRecord.fromJson(data);
        moodRecords.putIfAbsent(pid, () => []).add(m);
      }
      notifyListeners();
    });
  }

  // ------------- write helpers -------------

  Future<void> registerDoctor(Doctor d) async {
    await _db.collection('users').doc(d.id).set({
      ...d.toJson(),
      'role': 'doctor',
    });
  }

  Future<void> registerPatient(Patient p) async {
    await _db.collection('users').doc(p.id).set({
      ...p.toJson(),
      'role': 'patient',
    });
  }

  Future<void> registerParent(Parent p) async {
    await _db.collection('users').doc(p.id).set({
      ...p.toJson(),
      'role': 'parent',
    });
  }

  Future<void> pushVital(VitalSample s) async {
    await _db.collection('vitals').add(s.toJson());
  }

  Future<void> addDoctorNote(DoctorNote n, String text) async {
    await _db.collection('notes').add(n.toJson());
  }

  Future<void> addMedication(Medication m, Medication result) async {
    await _db.collection('medications').add(m.toJson());
  }

  Future<void> addAlert(AlertItem a) async {
    await _db.collection('alerts').add(a.toJson());
  }

  Future<void> addMood(MoodRecord m) async {
    await _db.collection('moods').add(m.toJson());
  }

  // ------------- getters -------------

  Doctor? getDoctorById(String id) => doctors[id];
  Patient? getPatientById(String id) => patients[id];
  Parent? getParentById(String id) => parents[id];

  List<VitalSample> getVitalsForPatient(String pid) =>
      vitals[pid] ?? [];

  List<DoctorNote> getNotesForPatient(String pid) =>
      doctorNotes[pid] ?? [];

  List<Medication> getMedicationsForPatient(String pid) =>
      medications[pid] ?? [];

  List<AlertItem> getAlertsForPatient(String pid) =>
      alerts[pid] ?? [];

  List<MoodRecord> getMoodForPatient(String pid) =>
      moodRecords[pid] ?? [];

  notesFor(String id) {}

  alertsFor(String patientId) {}

  void updateMedication(String patientId, Medication updatedMed) {}

  medicationsFor(String patientId) {}

  moodRecordsFor(String id) {}

  void toggleLocale() {}

  vitalsFor(String id) {}
}
