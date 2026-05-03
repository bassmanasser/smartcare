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
    final response = await PHIAService.ask(
      message,
      patientId: patientId,
      patientName: patientName,
      languageCode: languageCode,
      vitalsSummary: vitalsSummary,
    );
    final reply = (response['answer'] ?? '').toString().trim();

    if (reply.isEmpty) {
      throw Exception('Empty AI response');
    }

    return reply;
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
