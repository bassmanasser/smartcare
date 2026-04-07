import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalPatientService {
  static String todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<void> admitPatientToHospital({
    required String patientUid,
    required String institutionId,
    required String institutionName,
    required String assignedDepartment,
    required String patientStatus,
    required String priorityLevel,
    String assignedDoctorId = '',
    String assignedDoctorName = '',
    String assignedNurseId = '',
    String assignedNurseName = '',
    String notes = '',
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(patientUid).set({
      'institutionId': institutionId,
      'institutionName': institutionName,
      'arrivalDayKey': todayKey(),
      'arrivalTimestamp': FieldValue.serverTimestamp(),
      'patientStatus': patientStatus,
      'priorityLevel': priorityLevel,
      'assignedDepartment': assignedDepartment,
      'assignedDoctorId': assignedDoctorId,
      'assignedDoctorName': assignedDoctorName,
      'assignedNurseId': assignedNurseId,
      'assignedNurseName': assignedNurseName,
      'admissionNotes': notes,
      'isAdmittedToday': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('institutions')
        .doc(institutionId)
        .collection('today_patients')
        .doc(patientUid)
        .set({
      'patientId': patientUid,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'arrivalDayKey': todayKey(),
      'arrivalTimestamp': FieldValue.serverTimestamp(),
      'patientStatus': patientStatus,
      'priorityLevel': priorityLevel,
      'assignedDepartment': assignedDepartment,
      'assignedDoctorId': assignedDoctorId,
      'assignedDoctorName': assignedDoctorName,
      'assignedNurseId': assignedNurseId,
      'assignedNurseName': assignedNurseName,
      'admissionNotes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updatePatientRouting({
    required String patientUid,
    required String institutionId,
    required String patientStatus,
    required String priorityLevel,
    required String assignedDepartment,
    String assignedDoctorId = '',
    String assignedDoctorName = '',
    String assignedNurseId = '',
    String assignedNurseName = '',
    String notes = '',
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(patientUid).set({
      'patientStatus': patientStatus,
      'priorityLevel': priorityLevel,
      'assignedDepartment': assignedDepartment,
      'assignedDoctorId': assignedDoctorId,
      'assignedDoctorName': assignedDoctorName,
      'assignedNurseId': assignedNurseId,
      'assignedNurseName': assignedNurseName,
      'admissionNotes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('institutions')
        .doc(institutionId)
        .collection('today_patients')
        .doc(patientUid)
        .set({
      'patientStatus': patientStatus,
      'priorityLevel': priorityLevel,
      'assignedDepartment': assignedDepartment,
      'assignedDoctorId': assignedDoctorId,
      'assignedDoctorName': assignedDoctorName,
      'assignedNurseId': assignedNurseId,
      'assignedNurseName': assignedNurseName,
      'admissionNotes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> dischargePatient({
    required String patientUid,
    required String institutionId,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(patientUid).set({
      'patientStatus': 'Discharged',
      'isAdmittedToday': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('institutions')
        .doc(institutionId)
        .collection('today_patients')
        .doc(patientUid)
        .set({
      'patientStatus': 'Discharged',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}