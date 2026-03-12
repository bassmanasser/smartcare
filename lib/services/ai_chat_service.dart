import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatService {
  // غيري اللينك ده للباك إند بتاعك
  static const String baseUrl = 'https://YOUR_BACKEND_URL';

  static Future<String> sendMessage({
    required String patientId,
    required String patientName,
    required String message,
    required String languageCode,
    Map<String, dynamic>? latestVitals,
  }) async {
    final uri = Uri.parse('$baseUrl/ai/chat');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'patientId': patientId,
        'patientName': patientName,
        'message': message,
        'language': languageCode,
        'latestVitals': latestVitals,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI request failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['reply'] ?? '').toString();
  }
}