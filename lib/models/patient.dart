class Patient {
  final String id;
  final String name;
  final DateTime? birthDate;
  final String gender;
  final String? email;
  final String? phone;
  final String? profilePic;

  // الربط
  final String? doctorId;
  final String? parentId;

  // البيانات الطبية
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final List<String> currentMedications;

  // الوزن والطول
  final String? weight;
  final String? height;

  // الطوارئ
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  Patient({
    required this.id,
    required this.name,
    this.birthDate,
    required this.gender,
    this.email,
    this.phone,
    this.profilePic,
    this.doctorId,
    this.parentId,
    this.bloodType,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.currentMedications = const [],
    this.weight,
    this.height,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  // حساب العمر تلقائياً
  int get age {
    if (birthDate == null) return 0;

    DateTime today = DateTime.now();
    int age = today.year - birthDate!.year;

    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      age--;
    }

    return age;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      gender: json['gender'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profilePic: json['profilePic'] as String?,
      doctorId: json['doctorId'] as String?,
      parentId: json['parentId'] as String?,
      bloodType: json['bloodType'] as String?,
      allergies: List<String>.from(json['allergies'] ?? []),
      chronicDiseases: List<String>.from(json['chronicDiseases'] ?? []),
      currentMedications: List<String>.from(json['currentMedications'] ?? []),
      weight: json['weight'] as String?,
      height: json['height'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'email': email,
      'phone': phone,
      'profilePic': profilePic,
      'doctorId': doctorId,
      'parentId': parentId,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'currentMedications': currentMedications,
      'weight': weight,
      'height': height,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'age': age,
    };
  }
}