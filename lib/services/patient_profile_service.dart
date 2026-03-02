import 'package:cloud_firestore/cloud_firestore.dart';

class PatientProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateProfile({
    required String patientId,
    String? name,
    String? phone,
    int? age,
    String? gender,
    String? bloodType,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (bloodType != null) data['bloodType'] = bloodType;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(patientId).update(data);
    }
  }

  Future<void> updateEmergencyContact({
    required String patientId,
    required String name,
    required String phone,
  }) async {
    await _db.collection('users').doc(patientId).update({
      'emergencyContactName': name,
      'emergencyContactPhone': phone,
    });
  }
}