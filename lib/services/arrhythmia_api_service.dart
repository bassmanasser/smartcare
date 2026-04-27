import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ArrhythmiaApiService {
  static Future<String> checkArrhythmia(List<int> ppgValues) async {
    final uri = Uri.parse(
      '${ApiConfig.arrhythmiaBaseUrl}${ApiConfig.arrhythmiaPredictEndpoint}',
    );

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ppg': ppgValues,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Arrhythmia API error: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['result'] ?? 'Unknown').toString();
  }
}
