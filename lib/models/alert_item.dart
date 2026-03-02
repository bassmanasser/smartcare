class AlertItem {
  final String id;
  final String patientId;
  final String type;
  final String message;
  final String severity; // 'low' | 'medium' | 'high'
  final DateTime timestamp;

  AlertItem({
    required this.id,
    required this.patientId,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json, String id) {
    return AlertItem(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String,
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['t'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'type': type,
      'message': message,
      'severity': severity,
      't': timestamp.millisecondsSinceEpoch,
    };
  }
}
