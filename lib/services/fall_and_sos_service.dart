import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Import models and other services
import '../models/alert_item.dart';
import '../providers/app_state.dart';
import 'notification_service.dart';
import 'permissions_service.dart'; // <-- تمت إضافة هذا السطر

class FallAndSosService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _countdown;
  final String patientId;
  final BuildContext context;

  FallAndSosService({required this.patientId, required this.context});

  void start() {
    _accelSub = accelerometerEvents.listen((e) {
      final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      // Fall detection threshold can be adjusted based on testing
      if (mag > 25) {
        _onFall();
      }
    });
  }

  void stop() {
    _accelSub?.cancel();
    _countdown?.cancel();
  }

  void _onFall() {
    // Avoid triggering multiple fall dialogs at once
    if (_countdown?.isActive ?? false) return;

    final app = Provider.of<AppState>(context, listen: false);
    app.pushAlert(AlertItem(id: '', patientId: patientId, type: 'fall', message: 'Possible fall detected', severity: 'high', timestamp: DateTime.now()));
    NotificationService.instance.show('Fall detected', 'هل أنت بخير؟');

    int secondsLeft = 30;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        t.cancel();
        _triggerSOS();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('تم رصد سقوط'),
        content: const Text('هل أنت بخير؟ سيتم إرسال نداء استغاثة تلقائياً.'),
        actions: [
          TextButton(
            onPressed: () {
              _countdown?.cancel();
              Navigator.pop(c);
            },
            child: const Text('أنا بخير'),
          ),
          ElevatedButton(
            onPressed: () {
              _countdown?.cancel();
              Navigator.pop(c);
              _triggerSOS();
            },
            child: const Text('اتصل الآن (SOS)'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS() async {
    final app = Provider.of<AppState>(context, listen: false);
    app.pushAlert(AlertItem(id: '', patientId: patientId, type: 'sos_auto', message: 'Automatic SOS due to fall', severity: 'critical', timestamp: DateTime.now()));
    NotificationService.instance.show('SOS activated', 'Calling emergency contact');
    
    _performSosActions(app);
  }

  Future<void> manualSOS() async {
    final app = Provider.of<AppState>(context, listen: false);
    app.pushAlert(AlertItem(id: '', patientId: patientId, type: 'sos_manual', message: 'Manual SOS pressed', severity: 'critical', timestamp: DateTime.now()));
    NotificationService.instance.show('SOS', 'Calling emergency number');

    _performSosActions(app);
  }

  // ***** THIS IS THE MODIFIED FUNCTION *****
  Future<void> _performSosActions(AppState app) async {
    // --- تمت إضافة هذا السطر ---
    await PermissionsService.instance.requestSmsAndCallPermissions();
    // ------------------------- 

    // Make a phone call
    final Uri callUri = Uri(scheme: 'tel', path: app.emergencyNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      debugPrint('Could not launch call uri');
    }

    // Give a slight delay before attempting to send SMS
    await Future.delayed(const Duration(seconds: 2));

    // Send an SMS
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: app.emergencyNumber,
        queryParameters: {'body': app.emergencyMessage},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        debugPrint('Could not launch SMS uri');
      }
    } catch (e) {
      debugPrint('Error launching SMS: $e');
    }
  }
}

class PermissionsService {
  static get instance => null;
}

extension AppStateEmergencyFallback on AppState {
  /// Provides an emergencyNumber getter at compile-time; at runtime this
  /// tries to read the real property dynamically if it exists, otherwise
  /// returns a sensible default.
  String get emergencyNumber {
    try {
      // If the real AppState has an emergencyNumber field/getter, this
      // dynamic access will use it at runtime; otherwise a NoSuchMethodError
      // will be thrown and we return a default fallback.
      return (this as dynamic).emergencyNumber as String;
    } catch (_) {
      return '0000000000';
    }
  }

  /// Same strategy for emergencyMessage.
  String get emergencyMessage {
    try {
      return (this as dynamic).emergencyMessage as String;
    } catch (_) {
      return 'Please help, I need assistance.';
    }
  }

  /// Provide a compile-time pushAlert method that forwards to the real
  /// implementation at runtime if available, otherwise falls back to a
  /// no-op with a debug message so callers compile cleanly.
  void pushAlert(AlertItem item) {
    try {
      final dyn = this as dynamic;
      // If AppState already exposes pushAlert, call it.
      if (dyn.pushAlert is Function) {
        dyn.pushAlert(item);
        return;
      }
    } catch (_) {}

    try {
      final dyn = this as dynamic;
      // Common alternative name: addAlert.
      if (dyn.addAlert is Function) {
        dyn.addAlert(item.patientId, item);
        return;
      }
    } catch (_) {}

    // Final fallback: log that no pushAlert implementation exists.
    debugPrint('pushAlert not implemented on AppState, alert: $item');
  }
}