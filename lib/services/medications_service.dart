import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication.dart';

class MedicationsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب قائمة الأدوية لمريض معين
  Stream<List<Medication>> medicationsStream(String patientId) {
    return _db
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Medication.fromJson(data, doc.id);
      }).toList();
    });
  }

  // تحديث حالة الدواء (نشط/غير نشط)
  Future<void> updateMedicationStatus(String medId, bool isActive) async {
    await _db.collection('medications').doc(medId).update({
      'active': isActive,
    });
  }

  // حذف دواء
  Future<void> deleteMedication(String medId) async {
    await _db.collection('medications').doc(medId).delete();
  }
}