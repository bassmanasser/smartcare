class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? doctorId;
  final String? parentId;
  final String? email;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.doctorId,
    this.parentId,
    this.email,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? 'Unknown',
      doctorId: json['doctorId'] as String?,
      parentId: json['parentId'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'doctorId': doctorId,
      'parentId': parentId,
      'email': email,
    };
  }
}
