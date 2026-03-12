import 'package:google_generative_ai/google_generative_ai.dart';

class AiChatService {
  static const String _apiKey = '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';

  static Future<String> sendMessage({
    required String patientId,
    required String patientName,
    required String message,
    required String languageCode,
    Map<String, dynamic>? latestVitals,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      // تحويل العلامات الحيوية لنص عشان الـ AI يفهمها
      String vitalsInfo = latestVitals != null 
          ? "القراءات الحالية للمريض: ضغط الدم ${latestVitals['sys']}/${latestVitals['dia']}, نبض القلب ${latestVitals['hr']}, الأكسجين ${latestVitals['spo2']}%, السكر ${latestVitals['glucose']}."
          : "لا توجد قراءات حيوية متاحة حالياً.";

      final prompt = """
      أنت مساعد طبي ذكي في تطبيق SmartCare. 
      اسم المريض: $patientName.
      $vitalsInfo
      اللغة المطلوبة للرد: $languageCode.
      
      أجب على استفسار المريض بناءً على حالته الصحية الموضحة أعلاه. 
      إذا كانت القراءات خطيرة، اطلب منه التوجه للطوارئ فوراً.
      سؤال المريض: $message
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text ?? "عذراً، لم أستطع تحليل الطلب.";
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}