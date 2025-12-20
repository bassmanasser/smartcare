import 'package:cloud_firestore/cloud_firestore.dart';

/// =======================================================
///  Firestore Paths (هنظبطهم بعدين مع بعض)
/// =======================================================
/// افتراض حالي (مؤقت):
/// patients/{patientId}/vitals
/// patients/{patientId}/alerts
/// patients/{patientId}/medications
/// patients/{patientId}/moods
///
/// لو الداتا عندك في مكان تاني → هنغير هنا بس.
class FirestorePaths {
  static String patientDoc(String patientId) => 'patients/$patientId';

  static CollectionReference<Map<String, dynamic>> vitals(String patientId) =>
      FirebaseFirestore.instance.collection('${patientDoc(patientId)}/vitals');

  static CollectionReference<Map<String, dynamic>> alerts(String patientId) =>
      FirebaseFirestore.instance.collection('${patientDoc(patientId)}/alerts');

  static CollectionReference<Map<String, dynamic>> meds(String patientId) =>
      FirebaseFirestore.instance.collection('${patientDoc(patientId)}/medications');

  static CollectionReference<Map<String, dynamic>> moods(String patientId) =>
      FirebaseFirestore.instance.collection('${patientDoc(patientId)}/moods');
}

/// =======================================================
///  Helpers: parsing + safe getters
/// =======================================================
DateTime? tsToDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  return null;
}

double? toDoubleSafe(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? toIntSafe(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String strSafe(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

/// =======================================================
///  Repository: Fetch patient data for Insights / Timeline / PDF
/// =======================================================
class PatientDataRepository {
  /// Latest vitals (single doc) by timestamp/createdAt
  Stream<Map<String, dynamic>?> latestVitalsStream(String patientId) {
    final col = FirestorePaths.vitals(patientId);
    return col
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    });
  }

  Stream<List<Map<String, dynamic>>> vitalsStream(String patientId, {int limit = 50}) {
    final col = FirestorePaths.vitals(patientId);
    return col
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> alertsStream(String patientId, {int limit = 100}) {
    final col = FirestorePaths.alerts(patientId);
    return col
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> medsStream(String patientId) {
    final col = FirestorePaths.meds(patientId);
    return col
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> moodsStream(String patientId, {int limit = 100}) {
    final col = FirestorePaths.moods(patientId);
    return col
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<Map<String, dynamic>>> vitalsOnce(String patientId, {int limit = 80}) async {
    final snap = await FirestorePaths.vitals(patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> alertsOnce(String patientId, {int limit = 200}) async {
    final snap = await FirestorePaths.alerts(patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> medsOnce(String patientId) async {
    final snap = await FirestorePaths.meds(patientId).orderBy('name').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> moodsOnce(String patientId, {int limit = 200}) async {
    final snap = await FirestorePaths.moods(patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}

/// =======================================================
///  Rules / thresholds for insights (تعدليها براحتك)
/// =======================================================
class HealthRules {
  /// Glucose mg/dL ranges
  static bool glucoseLow(double g) => g < 70;
  static bool glucoseHigh(double g) => g >= 180;
  static bool glucoseMedium(double g) => g >= 140 && g < 180;

  /// HR ranges
  static bool hrLow(int hr) => hr < 50;
  static bool hrHigh(int hr) => hr > 110;

  /// SpO2
  static bool spo2Danger(int s) => s < 90;
  static bool spo2Warn(int s) => s >= 90 && s < 94;

  /// Temp
  static bool tempFever(double t) => t >= 38.0;
  static bool tempLow(double t) => t < 35.5;
}

/// =======================================================
///  Build short advice text
/// =======================================================
class AdviceBuilder {
  static List<String> glucoseAdvice(double g) {
    if (HealthRules.glucoseLow(g)) {
      return [
        'Low glucose detected.',
        'Take 15g fast sugar (juice / glucose tablets).',
        'Recheck after 15 minutes.',
        'If severe symptoms: trigger SOS / contact doctor.'
      ];
    }
    if (HealthRules.glucoseHigh(g)) {
      return [
        'High glucose detected.',
        'Drink water and avoid sugary food now.',
        'Take prescribed medication/insulin if applicable.',
        'Recheck in 1–2 hours.',
        'If > 250 mg/dL with symptoms: contact doctor.'
      ];
    }
    if (HealthRules.glucoseMedium(g)) {
      return [
        'Glucose is moderately elevated.',
        'Drink water, light activity if allowed.',
        'Prefer balanced meal, reduce sweets.',
        'Recheck later today.'
      ];
    }
    return ['Glucose is in a safe range. Keep healthy routine.'];
  }

  static List<String> fallAdvice() => [
        'Possible fall detected.',
        'Check patient status immediately.',
        'If no response: trigger SOS / call emergency contact.'
      ];
}
