import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class AlertsNotificationsBridge {
  AlertsNotificationsBridge._();
  static final AlertsNotificationsBridge instance = AlertsNotificationsBridge._();

  StreamSubscription? _sub;

  static String _prefsKey(String patientId) => 'last_alert_ts_$patientId';

  /// Start listening to alerts collection and show local notification on new alerts
  Future<void> startForPatient(String patientId) async {
    await NotificationService.instance.init();

    // stop old listener if any
    await stop();

    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt(_prefsKey(patientId)) ?? 0;
    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMillis);

    final q = FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('alerts')
        .orderBy('timestamp', descending: false)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(lastDate));

    _sub = q.snapshots().listen((snap) async {
      if (snap.docs.isEmpty) return;

      // update last timestamp to newest doc
      final lastDoc = snap.docs.last.data();
      final ts = (lastDoc['timestamp'] as Timestamp?)?.toDate();
      if (ts != null) {
        await prefs.setInt(_prefsKey(patientId), ts.millisecondsSinceEpoch);
      }

      // show notifications for each new alert doc
      for (final doc in snap.docs) {
        final data = doc.data();
        final msg = (data['message'] ?? 'New Alert').toString();
        final sev = (data['severity'] ?? 'low').toString().toLowerCase();

        final title = sev == 'high'
            ? '🚨 Critical Alert'
            : sev == 'medium'
                ? '⚠️ Warning'
                : 'ℹ️ Alert';

        // id: stable per doc id
        final id = NotificationService.instance.makeId('alert_${doc.id}');
        await NotificationService.instance.showInstant(
          id: id,
          title: title,
          body: msg,
        );
      }
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
