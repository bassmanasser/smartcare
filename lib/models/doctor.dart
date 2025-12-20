class Doctor {
  final String id;
  final String name;
  final String? specialty;

  Doctor({
    required this.id,
    required this.name,
    this.specialty,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
    };
  }
}
