class Institution {
  final String id;
  final String name;
  final String code;
  final String type;
  final String address;
  final String phone;
  final String email;
  final List<String> departments;
  final String status;

  Institution({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.address,
    required this.phone,
    required this.email,
    required this.departments,
    required this.status,
  });

  factory Institution.fromJson(Map<dynamic, dynamic> json) {
    return Institution(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? 'Hospital').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      departments: List<String>.from(json['departments'] ?? const []),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'address': address,
      'phone': phone,
      'email': email,
      'departments': departments,
      'status': status,
    };
  }
}