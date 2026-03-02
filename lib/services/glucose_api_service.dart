import 'dart:convert';
import 'package:http/http.dart' as http;

class GlucoseApiService {
  static const String baseUrl = 'https://fatmaff-glucose-api.hf.space';

  static Future<double> predictGlucose(List<int> irValues) async {
    final uri = Uri.parse('$baseUrl/predict');

    // 1. حساب متوسط الـ 20 قراءة لضمان أعلى دقة ممكنة
    int sum = 0;
    for (int val in irValues) {
      sum += val;
    }
    int averageIr = sum ~/ irValues.length; // المتوسط كرقم صحيح

    // 2. إرسال البيانات بنفس الشكل اللي الـ API طالبه بالظبط
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'max30102_ir': averageIr, // 👈 تم تعديل الاسم ليتطابق مع صورتك
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['glucose'] as num).toDouble();
    } else {
      throw Exception('Glucose API error ${response.statusCode}: ${response.body}');
    }
  }
}