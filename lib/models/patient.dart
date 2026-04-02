class Patient {
  final String id;
  final String name;
  final DateTime? birthDate;
  final String gender;
  final String? email;
  final String? phone;
  final String? profilePic;

  // الربط القديم
  final String? doctorId;
  final String? parentId;

  // الربط الجديد بالمؤسسة
  final String? assignedInstitutionId;
  final String? assignedInstitutionCode;
  final String? assignedInstitutionName;
  final String? assignedDepartment;
  final String? assignedDoctorUid;
  final String? queuePriority;
  final String? workflowStage;

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
    this.assignedInstitutionId,
    this.assignedInstitutionCode,
    this.assignedInstitutionName,
    this.assignedDepartment,
    this.assignedDoctorUid,
    this.queuePriority,
    this.workflowStage,
    this.bloodType,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.currentMedications = const [],
    this.weight,
    this.height,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required int age,
  });

  int get age {
    if (birthDate == null) return 0;

    final today = DateTime.now();
    int calculatedAge = today.year - birthDate!.year;

    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      calculatedAge--;
    }

    return calculatedAge;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      birthDate: json['birthDate'] != null && json['birthDate'].toString().isNotEmpty
          ? DateTime.tryParse(json['birthDate'].toString())
          : null,
      gender: (json['gender'] ?? 'Unknown').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      profilePic: json['profilePic']?.toString(),

      // القديم
      doctorId: json['doctorId']?.toString(),
      parentId: json['parentId']?.toString(),

      // الجديد
      assignedInstitutionId: json['assignedInstitutionId']?.toString(),
      assignedInstitutionCode: json['assignedInstitutionCode']?.toString(),
      assignedInstitutionName: json['assignedInstitutionName']?.toString(),
      assignedDepartment: json['assignedDepartment']?.toString(),
      assignedDoctorUid: json['assignedDoctorUid']?.toString(),
      queuePriority: json['queuePriority']?.toString(),
      workflowStage: json['workflowStage']?.toString(),

      bloodType: json['bloodType']?.toString(),
      allergies: List<String>.from(json['allergies'] ?? const []),
      chronicDiseases: List<String>.from(json['chronicDiseases'] ?? const []),
      currentMedications:
          List<String>.from(json['currentMedications'] ?? const []),
      weight: json['weight']?.toString(),
      height: json['height']?.toString(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
      age: 0,
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

      // القديم
      'doctorId': doctorId,
      'parentId': parentId,

      // الجديد
      'assignedInstitutionId': assignedInstitutionId,
      'assignedInstitutionCode': assignedInstitutionCode,
      'assignedInstitutionName': assignedInstitutionName,
      'assignedDepartment': assignedDepartment,
      'assignedDoctorUid': assignedDoctorUid,
      'queuePriority': queuePriority,
      'workflowStage': workflowStage,

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

  Patient copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? email,
    String? phone,
    String? profilePic,
    String? doctorId,
    String? parentId,
    String? assignedInstitutionId,
    String? assignedInstitutionCode,
    String? assignedInstitutionName,
    String? assignedDepartment,
    String? assignedDoctorUid,
    String? queuePriority,
    String? workflowStage,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicDiseases,
    List<String>? currentMedications,
    String? weight,
    String? height,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
      doctorId: doctorId ?? this.doctorId,
      parentId: parentId ?? this.parentId,
      assignedInstitutionId:
          assignedInstitutionId ?? this.assignedInstitutionId,
      assignedInstitutionCode:
          assignedInstitutionCode ?? this.assignedInstitutionCode,
      assignedInstitutionName:
          assignedInstitutionName ?? this.assignedInstitutionName,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      assignedDoctorUid: assignedDoctorUid ?? this.assignedDoctorUid,
      queuePriority: queuePriority ?? this.queuePriority,
      workflowStage: workflowStage ?? this.workflowStage,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      currentMedications: currentMedications ?? this.currentMedications,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      age: age,
    );
  }
}