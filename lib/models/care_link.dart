import 'package:cloud_firestore/cloud_firestore.dart';

enum LinkUserRole { doctor, parent }
enum LinkStatus { pending, approved, rejected, removed, blocked }
enum RequestDirection { patientToDoctor, patientToParent, doctorToPatient, parentToPatient }

String _enumToString(Object e) => e.toString().split('.').last;

T _enumFromString<T>(List<T> values, String? raw, T fallback) {
  if (raw == null) return fallback;
  for (final v in values) {
    if (_enumToString(v as Object) == raw) return v;
  }
  return fallback;
}

class CareLink {
  final String id;
  final String patientId;
  final String linkedUserId;
  final LinkUserRole linkedUserRole;
  final LinkStatus status;
  final RequestDirection requestDirection;

  final String relationshipLabel; // Cardiologist / Father / Mother / etc
  final bool isPrimary;

  final bool canViewVitals;
  final bool canViewReports;
  final bool canViewMedications;
  final bool canWriteNotes;
  final bool canReceiveAlerts;
  final bool canManageCarePlan;

  final String notes;

  final String requestedBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? respondedAt;

  const CareLink({
    required this.id,
    required this.patientId,
    required this.linkedUserId,
    required this.linkedUserRole,
    required this.status,
    required this.requestDirection,
    required this.relationshipLabel,
    required this.isPrimary,
    required this.canViewVitals,
    required this.canViewReports,
    required this.canViewMedications,
    required this.canWriteNotes,
    required this.canReceiveAlerts,
    required this.canManageCarePlan,
    required this.notes,
    required this.requestedBy,
    this.createdAt,
    this.updatedAt,
    this.respondedAt,
  });

  factory CareLink.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    return CareLink(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      linkedUserId: data['linkedUserId'] ?? '',
      linkedUserRole: _enumFromString(
        LinkUserRole.values,
        data['linkedUserRole'],
        LinkUserRole.doctor,
      ),
      status: _enumFromString(
        LinkStatus.values,
        data['status'],
        LinkStatus.pending,
      ),
      requestDirection: _enumFromString(
        RequestDirection.values,
        data['requestDirection'],
        RequestDirection.patientToDoctor,
      ),
      relationshipLabel: data['relationshipLabel'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
      canViewVitals: data['canViewVitals'] ?? true,
      canViewReports: data['canViewReports'] ?? true,
      canViewMedications: data['canViewMedications'] ?? true,
      canWriteNotes: data['canWriteNotes'] ?? false,
      canReceiveAlerts: data['canReceiveAlerts'] ?? true,
      canManageCarePlan: data['canManageCarePlan'] ?? false,
      notes: data['notes'] ?? '',
      requestedBy: data['requestedBy'] ?? '',
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      respondedAt: data['respondedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'linkedUserId': linkedUserId,
      'linkedUserRole': _enumToString(linkedUserRole),
      'status': _enumToString(status),
      'requestDirection': _enumToString(requestDirection),
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'respondedAt': respondedAt,
    };
  }

  CareLink copyWith({
    String? id,
    String? patientId,
    String? linkedUserId,
    LinkUserRole? linkedUserRole,
    LinkStatus? status,
    RequestDirection? requestDirection,
    String? relationshipLabel,
    bool? isPrimary,
    bool? canViewVitals,
    bool? canViewReports,
    bool? canViewMedications,
    bool? canWriteNotes,
    bool? canReceiveAlerts,
    bool? canManageCarePlan,
    String? notes,
    String? requestedBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? respondedAt,
  }) {
    return CareLink(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      linkedUserRole: linkedUserRole ?? this.linkedUserRole,
      status: status ?? this.status,
      requestDirection: requestDirection ?? this.requestDirection,
      relationshipLabel: relationshipLabel ?? this.relationshipLabel,
      isPrimary: isPrimary ?? this.isPrimary,
      canViewVitals: canViewVitals ?? this.canViewVitals,
      canViewReports: canViewReports ?? this.canViewReports,
      canViewMedications: canViewMedications ?? this.canViewMedications,
      canWriteNotes: canWriteNotes ?? this.canWriteNotes,
      canReceiveAlerts: canReceiveAlerts ?? this.canReceiveAlerts,
      canManageCarePlan: canManageCarePlan ?? this.canManageCarePlan,
      notes: notes ?? this.notes,
      requestedBy: requestedBy ?? this.requestedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}