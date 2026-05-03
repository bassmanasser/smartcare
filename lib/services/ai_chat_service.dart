import 'phia_service.dart';

class AiChatService {
  static Future<String> sendMessage({
    required String patientId,
    required String patientName,
    required String message,
    required String languageCode,
    Map<String, dynamic>? latestVitals,
  }) async {
    final user = await PHIAService.waitForSignedInUser();
    if (user == null) {
      return languageCode == 'ar'
          ? 'من فضلك سجلي الدخول أولاً.'
          : 'Please log in first.';
    }

    final vitalsSummary = _buildVitalsSummary(latestVitals, languageCode);
    final prompt = _buildPrompt(
      patientName: patientName,
      message: message,
      languageCode: languageCode,
      vitalsSummary: vitalsSummary,
    );

    final response = await PHIAService.ask(prompt);
    final reply = (response['answer'] ?? '').toString().trim();

    if (reply.isEmpty) {
      throw Exception('Empty AI response');
    }

    return reply;
  }

  static String _buildPrompt({
    required String patientName,
    required String message,
    required String languageCode,
    required String vitalsSummary,
  }) {
    if (languageCode == 'ar') {
      return '''
اسم المريض: $patientName
ملخص القراءات الحيوية: $vitalsSummary

سؤال المريض:
$message

جاوب كمساعد صحي داخل تطبيق SmartCare. استخدم العربية، خلي الإجابة بسيطة وآمنة، واذكر أن الحالات الطارئة تحتاج تواصل فوري مع الطبيب أو الطوارئ.
''';
    }

    return '''
Patient name: $patientName
Latest vitals summary: $vitalsSummary

Patient question:
$message

Answer as the SmartCare health assistant. Keep it simple, safe, and remind the patient to contact a doctor or emergency services for urgent symptoms.
''';
  }

  static String _buildVitalsSummary(
    Map<String, dynamic>? latestVitals,
    String languageCode,
  ) {
    if (latestVitals == null || latestVitals.isEmpty) {
      return languageCode == 'ar'
          ? 'لا توجد قراءات حيوية حديثة متاحة.'
          : 'No recent vital readings are available.';
    }

    final hr = latestVitals['hr'];
    final spo2 = latestVitals['spo2'];
    final sys = latestVitals['sys'];
    final dia = latestVitals['dia'];
    final glucose = latestVitals['glucose'];
    final temperature = latestVitals['temperature'];
    final fallFlag = latestVitals['fallFlag'];

    if (languageCode == 'ar') {
      return 'النبض: $hr، الأكسجين: $spo2%، الضغط: $sys/$dia، السكر: $glucose، الحرارة: $temperature، سقوط: $fallFlag';
    }

    return 'Heart rate: $hr, SpO2: $spo2%, blood pressure: $sys/$dia, glucose: $glucose, temperature: $temperature, fall detected: $fallFlag';
  }
}
