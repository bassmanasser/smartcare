import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ai_message.dart';

class AiBotService {
  static const String _apiKey = 'PUT_YOUR_API_KEY_HERE';
  static const String _endpoint =
      'https://api.openai.com/v1/chat/completions';

  final _firestore = FirebaseFirestore.instance;

  Future<List<AiMessage>> loadHistory(String patientId) async {
    final snap = await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('ai_chat')
        .orderBy('timestamp')
        .get();

    return snap.docs
        .map((d) => AiMessage.fromJson(d.data()))
        .toList();
  }

  Future<AiMessage> sendMessage({
    required String patientId,
    required String message,
  }) async {
    final userMsg = AiMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('ai_chat')
        .add(userMsg.toJson());

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a medical assistant. Give safe, non-diagnostic advice."
          },
          {"role": "user", "content": message}
        ],
      }),
    );

    final data = jsonDecode(response.body);
    final aiText =
        data['choices'][0]['message']['content'] as String;

    final aiMsg = AiMessage(
      role: 'assistant',
      content: aiText,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('ai_chat')
        .add(aiMsg.toJson());

    return aiMsg;
  }
}
