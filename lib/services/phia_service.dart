import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PHIAService {
  // اسم الدالة يجب أن يطابق تماماً ما تم رفعه على Firebase
  static final _fn = FirebaseFunctions.instance.httpsCallable(
    'askHealthAgent',
    options: HttpsCallableOptions(
      timeout: const Duration(seconds: 120),
    ),
  );

  static Future<Map<String, dynamic>> ask(String question) async {
    try {
      final user = await waitForSignedInUser();
      if (user == null) {
        return {'answer': 'Please log in first.', 'alerts': []};
      }

      await user.getIdToken(true);
      final result = await _fn.call({'question': question});
      return {
        'answer': result.data['answer'] as String? ?? 'No answer.',
        'alerts': List<String>.from(result.data['alerts'] ?? []),
      };
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return {'answer': 'Please log in first.', 'alerts': []};
      }
      return {'answer': 'Error: ${e.message}', 'alerts': []};
    } catch (e) {
      return {'answer': 'Connection error. Check internet.', 'alerts': []};
    }
  }

  static Future<User?> waitForSignedInUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) return currentUser;

    try {
      return await FirebaseAuth.instance
          .idTokenChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return FirebaseAuth.instance.currentUser;
    }
  }
}
