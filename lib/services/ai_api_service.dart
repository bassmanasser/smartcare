import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AiApiService {
  static Future<Map<String, dynamic>> analyzeHeart({
    required String userId,
    required int fs,
    required List<int> ppgValues,
  }) async {
    final url = Uri.parse(
      ApiConfig.baseUrl + ApiConfig.analyzeEndpoint,
    );

    final body = {
      "user_id": userId,
      "fs": fs,
      "ppg_values": ppgValues,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "AI API Error ${response.statusCode}: ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body);
    return Map<String, dynamic>.from(decoded);
  }
}
