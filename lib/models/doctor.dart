class Doctor {
  final String uid;
  final String name;
  final String email;
  final String mainSpecialty;
  final String subSpecialty;

  /// Verification
  final String verificationStatus; // pending / approved / rejected
  final String? rejectionReason;   // optional
  final String? corneaImageUrl;    // optional (لو حابة تسيبيه)
  final String? licenseQrData;     // QR payload

  Doctor({
    required this.uid,
    required this.name,
    required this.email,
    required this.mainSpecialty,
    required this.subSpecialty,
    this.verificationStatus = "pending",
    this.rejectionReason,
    this.corneaImageUrl,
    this.licenseQrData,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "mainSpecialty": mainSpecialty,
      "subSpecialty": subSpecialty,
      "verificationStatus": verificationStatus,
      "rejectionReason": rejectionReason,
      "corneaImageUrl": corneaImageUrl,
      "licenseQrData": licenseQrData,
      "createdAt": DateTime.now().toIso8601String(),
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      uid: map["uid"] ?? "",
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      mainSpecialty: map["mainSpecialty"] ?? "",
      subSpecialty: map["subSpecialty"] ?? "",
      verificationStatus: map["verificationStatus"] ?? "pending",
      rejectionReason: map["rejectionReason"],
      corneaImageUrl: map["corneaImageUrl"],
      licenseQrData: map["licenseQrData"],
    );
  }

  List<String> get availableSlots => [];

  String get id => uid;

  String get specialty => "$mainSpecialty - $subSpecialty";

  double get consultationFee => 0.0;

  String get clinicAddress => "Clinic Address";

  static fromJson(Map<String, dynamic> data) {}
}