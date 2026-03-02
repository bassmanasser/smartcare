import 'dart:convert';
import 'package:http/http.dart' as http;

class ArrhythmiaApiService {
  // 1. تأكدي إن اللينك ده بتاع الـ Arrhythmia مش بتاع السكر
  static const String baseUrl = 'https://mariam2112-smartheart-api.hf.space/predict';

  static Future<String> checkArrhythmia(List<int> ppgValues) async {
    // 2. تأكدي إن الكلمة دي مطابقة لكود البايثون
    final uri = Uri.parse('$baseUrl/predict'); 

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        // 3. تأكدي إن اسم المتغير ده هو اللي البايثون مستنيه (مثلاً 'ppg' أو 'signal')
        'ppg': ppgValues, 
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'].toString(); // وتأكدي من اسم النتيجة اللي بترجع
    } else {
      throw Exception('API Error 404: ${response.body}');
    }
  }
}