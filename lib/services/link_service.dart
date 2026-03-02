import 'package:cloud_firestore/cloud_firestore.dart';

class LinkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ربط المريض بدكتور عن طريق الـ ID
  Future<void> linkToDoctor(String patientUid, String doctorId) async {
    await _db.collection('users').doc(patientUid).update({
      'doctorId': doctorId,
    });
  }

  // ربط المريض بولي أمر
  Future<void> linkToParent(String patientUid, String parentId) async {
    await _db.collection('users').doc(patientUid).update({
      'parentId': parentId,
    });
  }
}