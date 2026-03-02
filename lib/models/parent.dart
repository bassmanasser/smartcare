class Parent {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? nationalId; // الرقم القومي للتوثيق
  final String relation; 
  final String? homeAddress; // العنوان للطوارئ
  final List<String> familyMedicalHistory; // تاريخ العائلة المرضي
  final List<String> childrenIds;

  Parent({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.nationalId,
    required this.relation,
    this.homeAddress,
    this.familyMedicalHistory = const [],
    this.childrenIds = const [],
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      nationalId: json['nationalId'] as String?,
      relation: json['relation'] as String? ?? 'Parent',
      homeAddress: json['homeAddress'] as String?,
      familyMedicalHistory: List<String>.from(json['familyMedicalHistory'] ?? []),
      childrenIds: List<String>.from(json['childrenIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'nationalId': nationalId,
      'relation': relation,
      'homeAddress': homeAddress,
      'familyMedicalHistory': familyMedicalHistory,
      'childrenIds': childrenIds,
    };
  }
}