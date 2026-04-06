class Doctor {
  final String uid;
  final String name;
  final String email;

  // Institution-based fields
  final String institutionId;
  final String institutionName;
  final String institutionCode;
  final String departmentId;
  final String departmentName;
  final String staffRole; // doctor / nurse / triage_staff / hospital_admin
  final String medicalRole;
  final String employeeId;
  final String licenseNumber;
  final String workPhone;
  final String approvalStatus; // pending / approved / rejected
  final String availabilityStatus; // on_duty / off_duty / available / emergency_only
  final String? rejectionReason;
  final String? uploadProofUrl;

  // Keep these to avoid breaking older UI pieces
  final String mainSpecialty;
  final String subSpecialty;

  Doctor({
    required this.uid,
    required this.name,
    required this.email,
    required this.institutionId,
    required this.institutionName,
    required this.institutionCode,
    required this.departmentId,
    required this.departmentName,
    required this.staffRole,
    required this.medicalRole,
    required this.employeeId,
    required this.licenseNumber,
    required this.workPhone,
    required this.approvalStatus,
    required this.availabilityStatus,
    this.rejectionReason,
    this.uploadProofUrl,
    required this.mainSpecialty,
    required this.subSpecialty, required String verificationStatus, required corneaImageUrl,
  });

  factory Doctor.fromJson(Map<dynamic, dynamic> map) {
    return Doctor(
      uid: (map['uid'] ?? map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      institutionId: (map['institutionId'] ?? '').toString(),
      institutionName: (map['institutionName'] ?? '').toString(),
      institutionCode: (map['institutionCode'] ?? '').toString(),
      departmentId: (map['departmentId'] ?? '').toString(),
      departmentName: (map['departmentName'] ?? '').toString(),
      staffRole: (map['staffRole'] ?? map['role'] ?? 'doctor').toString(),
      medicalRole: (map['medicalRole'] ?? 'Medical Staff').toString(),
      employeeId: (map['employeeId'] ?? '').toString(),
      licenseNumber: (map['licenseNumber'] ?? '').toString(),
      workPhone: (map['workPhone'] ?? '').toString(),
      approvalStatus: (map['approvalStatus'] ?? 'pending').toString(),
      availabilityStatus: (map['availabilityStatus'] ?? 'available').toString(),
      rejectionReason: map['rejectionReason']?.toString(),
      uploadProofUrl: map['uploadProofUrl']?.toString(),
      mainSpecialty: (map['mainSpecialty'] ?? map['specialty'] ?? '').toString(),
      subSpecialty: (map['subSpecialty'] ?? '').toString(), verificationStatus: '', corneaImageUrl: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': staffRole,
      'staffRole': staffRole,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'institutionCode': institutionCode,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'medicalRole': medicalRole,
      'employeeId': employeeId,
      'licenseNumber': licenseNumber,
      'workPhone': workPhone,
      'approvalStatus': approvalStatus,
      'availabilityStatus': availabilityStatus,
      'rejectionReason': rejectionReason,
      'uploadProofUrl': uploadProofUrl,
      'mainSpecialty': mainSpecialty,
      'subSpecialty': subSpecialty,
      'profileCompleted': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  String get id => uid;

  String get specialty {
    if (mainSpecialty.isEmpty && subSpecialty.isEmpty) return departmentName;
    if (subSpecialty.isEmpty) return mainSpecialty;
    return '$mainSpecialty - $subSpecialty';
  }

  double get consultationFee => 0.0;
  String get clinicAddress => institutionName;
  List<dynamic> get availableSlots => [];

  get doctorId => null;

  get isApproved => null;

  get fee => null;

  Map<String, dynamic> toMap() {
    return toJson();
  }
}