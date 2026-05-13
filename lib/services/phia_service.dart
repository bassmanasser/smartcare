import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PHIAService {
  static final _fn = FirebaseFunctions.instance.httpsCallable(
    'askHealthAgent',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 120),
    ),
  );

  static Future<Map<String, dynamic>> ask(
    String question, {
    String? patientId,
    String? patientName,
    String? languageCode,
    String? vitalsSummary,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('not_logged_in');
    }

    try {
      // Force refresh token
      await user.getIdToken(true);

      final result = await _fn.call({
        'question': question,
        if (patientId != null) 'patientId': patientId,
        if (patientName != null) 'patientName': patientName,
        if (languageCode != null) 'languageCode': languageCode,
        if (vitalsSummary != null) 'vitalsSummary': vitalsSummary,
      });

      return {
        'answer': result.data['answer'] as String? ?? 'No answer.',
        'alerts': List<String>.from(
          result.data['alerts'] ?? [],
        ),
      };
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        'FirebaseFunctionsException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Connection error: $e',
      );
    }
  }
}