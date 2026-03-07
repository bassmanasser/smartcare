import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/care_link.dart';

class CareLinkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _links =>
      _db.collection('care_links');

  Future<String> sendDoctorRequest({
    required String patientId,
    required String doctorId,
    required String requestedBy,
    String relationshipLabel = 'Doctor',
    bool isPrimary = false,
    bool canViewVitals = true,
    bool canViewReports = true,
    bool canViewMedications = true,
    bool canWriteNotes = true,
    bool canReceiveAlerts = true,
    bool canManageCarePlan = false,
    String notes = '',
  }) async {
    final existing = await _links
        .where('patientId', isEqualTo: patientId)
        .where('linkedUserId', isEqualTo: doctorId)
        .where('linkedUserRole', isEqualTo: 'doctor')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final old = existing.docs.first;
      final status = old.data()['status'];

      if (status == 'approved') {
        throw Exception('This doctor is already linked.');
      }

      await old.reference.update({
        'status': 'pending',
        'requestDirection': 'patientToDoctor',
        'relationshipLabel': relationshipLabel,
        'isPrimary': isPrimary,
        'canViewVitals': canViewVitals,
        'canViewReports': canViewReports,
        'canViewMedications': canViewMedications,
        'canWriteNotes': canWriteNotes,
        'canReceiveAlerts': canReceiveAlerts,
        'canManageCarePlan': canManageCarePlan,
        'notes': notes,
        'requestedBy': requestedBy,
        'updatedAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });
      return old.id;
    }

    final doc = await _links.add({
      'patientId': patientId,
      'linkedUserId': doctorId,
      'linkedUserRole': 'doctor',
      'status': 'pending',
      'requestDirection': 'patientToDoctor',
      'relationshipLabel': relationshipLabel,
      'isPrimary': isPrimary,
      'canViewVitals': canViewVitals,
      'canViewReports': canViewReports,
      'canViewMedications': canViewMedications,
      'canWriteNotes': canWriteNotes,
      'canReceiveAlerts': canReceiveAlerts,
      'canManageCarePlan': canManageCarePlan,
      'notes': notes,
      'requestedBy': requestedBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });

    return doc.id;
  }

  Future<String> sendParentRequest({
    required String patientId,
    required String parentId,
    required String requestedBy,
    String relationshipLabel = 'Family',
    bool canViewVitals = true,
    bool canViewReports = true,
    bool canViewMedications = true,
    bool canReceiveAlerts = true,
    String notes = '',
  }) async {
    final existing = await _links
        .where('patientId', isEqualTo: patientId)
        .where('linkedUserId', isEqualTo: parentId)
        .where('linkedUserRole', isEqualTo: 'parent')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final old = existing.docs.first;
      final status = old.data()['status'];

      if (status == 'approved') {
        throw Exception('This family member is already linked.');
      }

      await old.reference.update({
        'status': 'pending',
        'requestDirection': 'patientToParent',
        'relationshipLabel': relationshipLabel,
        'canViewVitals': canViewVitals,
        'canViewReports': canViewReports,
        'canViewMedications': canViewMedications,
        'canWriteNotes': false,
        'canReceiveAlerts': canReceiveAlerts,
        'canManageCarePlan': false,
        'notes': notes,
        'requestedBy': requestedBy,
        'updatedAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });
      return old.id;
    }

    final doc = await _links.add({
      'patientId': patientId,
      'linkedUserId': parentId,
      'linkedUserRole': 'parent',
      'status': 'pending',
      'requestDirection': 'patientToParent',
      'relationshipLabel': relationshipLabel,
      'isPrimary': false,
      'canViewVitals': canViewVitals,
      'canViewReports': canViewReports,
      'canViewMedications': canViewMedications,
      'canWriteNotes': false,
      'canReceiveAlerts': canReceiveAlerts,
      'canManageCarePlan': false,
      'notes': notes,
      'requestedBy': requestedBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });

    return doc.id;
  }

  Stream<List<CareLink>> patientLinksStream(String patientId) {
    return _links
        .where('patientId', isEqualTo: patientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CareLink.fromDoc).toList());
  }

  Stream<List<CareLink>> incomingRequestsForUser(String userId) {
    return _links
        .where('linkedUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CareLink.fromDoc).toList());
  }

  Stream<List<CareLink>> approvedDoctorsForPatient(String patientId) {
    return _links
        .where('patientId', isEqualTo: patientId)
        .where('linkedUserRole', isEqualTo: 'doctor')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snap) => snap.docs.map(CareLink.fromDoc).toList());
  }

  Future<void> acceptRequest(String linkId) async {
    final ref = _links.doc(linkId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Request not found');

    final data = snap.data()!;
    final patientId = data['patientId'];
    final role = data['linkedUserRole'];
    final isPrimary = data['isPrimary'] == true;

    if (role == 'doctor' && isPrimary) {
      final previousPrimary = await _links
          .where('patientId', isEqualTo: patientId)
          .where('linkedUserRole', isEqualTo: 'doctor')
          .where('status', isEqualTo: 'approved')
          .where('isPrimary', isEqualTo: true)
          .get();

      final batch = _db.batch();

      for (final doc in previousPrimary.docs) {
        if (doc.id != linkId) {
          batch.update(doc.reference, {
            'isPrimary': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      batch.update(ref, {
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
        'respondedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return;
    }

    await ref.update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRequest(String linkId) async {
    await _links.doc(linkId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeLink(String linkId) async {
    await _links.doc(linkId).update({
      'status': 'removed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockLink(String linkId) async {
    await _links.doc(linkId).update({
      'status': 'blocked',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setPrimaryDoctor({
    required String patientId,
    required String linkId,
  }) async {
    final approvedDoctors = await _links
        .where('patientId', isEqualTo: patientId)
        .where('linkedUserRole', isEqualTo: 'doctor')
        .where('status', isEqualTo: 'approved')
        .get();

    final batch = _db.batch();

    for (final doc in approvedDoctors.docs) {
      batch.update(doc.reference, {
        'isPrimary': doc.id == linkId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> updatePermissions({
    required String linkId,
    required bool canViewVitals,
    required bool canViewReports,
    required bool canViewMedications,
    required bool canWriteNotes,
    required bool canReceiveAlerts,
    required bool canManageCarePlan,
    required String notes,
    required String relationshipLabel,
  }) async {
    await _links.doc(linkId).update({
      'canViewVitals': canViewVitals,
      'canViewReports': canViewReports,
      'canViewMedications': canViewMedications,
      'canWriteNotes': canWriteNotes,
      'canReceiveAlerts': canReceiveAlerts,
      'canManageCarePlan': canManageCarePlan,
      'notes': notes,
      'relationshipLabel': relationshipLabel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}