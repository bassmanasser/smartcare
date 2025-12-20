import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AlertsNotificationsListener {
  AlertsNotificationsListener._();
  static final instance = AlertsNotificationsListener._();

  StreamSubscription? _sub;
  String? _lastId;

  void start(String patientId) {
    _sub?.cancel();

    _sub = FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) async {
      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first;
      if (_lastId == doc.id) return;
      _lastId = doc.id;

      final data = doc.data();

      await NotificationService.instance.showNow(
        id: 1001,
        title: 'SmartCare Alert',
        body: data['message'] ?? 'New alert detected',
      );
    });
  }

  void stop() {
    _sub?.cancel();
  }
}
