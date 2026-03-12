class ParentModel {
  final String uid;
  final String name;
  final String phone;
  final String relationship;
  final String address;
  final String emergencyPhone;
  final String nationalId;
  final String gender;
  final String dateOfBirth;
  final bool notificationsEnabled;
  final bool criticalAlertsOnly;
  final List<String> linkedPatients;

  ParentModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.address,
    required this.emergencyPhone,
    required this.nationalId,
    required this.gender,
    required this.dateOfBirth,
    required this.notificationsEnabled,
    required this.criticalAlertsOnly,
    required this.linkedPatients,
  });

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      uid: (map['uid'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      relationship: (map['relationship'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      emergencyPhone: (map['emergencyPhone'] ?? '').toString(),
      nationalId: (map['nationalId'] ?? '').toString(),
      gender: (map['gender'] ?? '').toString(),
      dateOfBirth: (map['dateOfBirth'] ?? '').toString(),
      notificationsEnabled: map['notificationsEnabled'] == true,
      criticalAlertsOnly: map['criticalAlertsOnly'] == true,
      linkedPatients: List<String>.from(map['linkedPatients'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'address': address,
      'emergencyPhone': emergencyPhone,
      'nationalId': nationalId,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'notificationsEnabled': notificationsEnabled,
      'criticalAlertsOnly': criticalAlertsOnly,
      'linkedPatients': linkedPatients,
    };
  }

  ParentModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? relationship,
    String? address,
    String? emergencyPhone,
    String? nationalId,
    String? gender,
    String? dateOfBirth,
    bool? notificationsEnabled,
    bool? criticalAlertsOnly,
    List<String>? linkedPatients,
  }) {
    return ParentModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      address: address ?? this.address,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      nationalId: nationalId ?? this.nationalId,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      criticalAlertsOnly: criticalAlertsOnly ?? this.criticalAlertsOnly,
      linkedPatients: linkedPatients ?? this.linkedPatients,
    );
  }
}