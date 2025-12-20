class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole; // 'doctor' or 'patient'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderRole: json['senderRole'] as String? ?? 'patient',
      text: json['text'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['t'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      't': timestamp.millisecondsSinceEpoch,
    };
  }
}
