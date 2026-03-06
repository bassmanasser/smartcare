class Doctor {
  final String uid;
  final String doctorID; // كود الربط اللي هيظهر للمريض
  final String name;
  final String email;
  final String mainSpecialty;
  final String subSpecialty;
  
  // البيانات الإضافية للعيادة
  final String? price; 
  final String? address; 
  final List<String>? workingDays; 
  final String? workingHours;

  /// Verification
  final String verificationStatus; // pending / approved / rejected
  final String? rejectionReason;   // optional
  final String? corneaImageUrl;    
  final String? licenseQrData;     // QR payload

  Doctor({
    required this.uid,
    this.doctorID = "", // قيمة افتراضية
    required this.name,
    required this.email,
    required this.mainSpecialty,
    required this.subSpecialty,
    this.price,
    this.address,
    this.workingDays,
    this.workingHours,
    this.verificationStatus = "pending",
    this.rejectionReason,
    this.corneaImageUrl,
    this.licenseQrData,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "doctorID": doctorID,
      "name": name,
      "email": email,
      "mainSpecialty": mainSpecialty,
      "subSpecialty": subSpecialty,
      "price": price,
      "address": address,
      "workingDays": workingDays ?? [],
      "workingHours": workingHours,
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
      doctorID: map["doctorID"] ?? "",
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      mainSpecialty: map["mainSpecialty"] ?? "",
      subSpecialty: map["subSpecialty"] ?? "",
      price: map["price"],
      address: map["address"],
      workingDays: map["workingDays"] != null ? List<String>.from(map["workingDays"]) : [],
      workingHours: map["workingHours"],
      verificationStatus: map["verificationStatus"] ?? "pending",
      rejectionReason: map["rejectionReason"],
      corneaImageUrl: map["corneaImageUrl"],
      licenseQrData: map["licenseQrData"],
    );
  }

  List<String> get availableSlots => ["10:00 AM", "11:00 AM", "12:00 PM", "01:00 PM", "02:00 PM"];

  String get id => uid;

  String get specialty => "$mainSpecialty - $subSpecialty";

  double get consultationFee => double.tryParse(price ?? "0") ?? 0.0;

  String get clinicAddress => address ?? "لم يتم تحديد العنوان";

  static fromJson(Map<String, dynamic> data) {}

  toJson() {}
}