import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare/models/vital_sample.dart';

class VitalsInsightsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إعدادات بسيطة لمنع تكرار نفس التحذير بسرعة
  static const Duration _dedupeWindow = Duration(minutes: 1);

  /// Analyze vitals (latest) and write alerts to:
  /// patients/{patientId}/alerts
  Future<void> analyzeAndStore({
    required String patientId,
    required dynamic v, // object returned by latestVitalsStream (has hr/spo2/sys/dia/glucose/temperature/fallFlag)
  }) async {
    if (v == null) return;

    // read values safely
    final int? hr = _tryInt(() => v.hr);
    final int? spo2 = _tryInt(() => v.spo2);
    final int? sys = _tryInt(() => v.sys);
    final int? dia = _tryInt(() => v.dia);
    final double? glucose = _tryDouble(() => v.glucose);
    final double? temp = _tryDouble(() => v.temperature);
    final bool fall = _tryBool(() => v.fallFlag) ?? false;

    final now = DateTime.now();

    // build warnings
    final alerts = <_BuiltAlert>[];

    // FALL
    if (fall) {
      alerts.add(_BuiltAlert(
        severity: 'high',
        title: 'Fall detected',
        message:
            '⚠️ Fall detected. If the patient is injured, unconscious, or has severe pain, seek urgent help immediately.',
      ));
    }

    // SpO2
    if (spo2 != null) {
      if (spo2 < 90) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'Low oxygen saturation',
          message:
              'SpO₂ is $spo2%. This is very low. If there is shortness of breath, chest pain, confusion, or bluish lips, seek urgent medical care.',
        ));
      } else if (spo2 < 94) {
        alerts.add(_BuiltAlert(
          severity: 'medium',
          title: 'Borderline oxygen saturation',
          message:
              'SpO₂ is $spo2%. Monitor closely. Re-check sensor placement and measure again after rest.',
        ));
      }
    }

    // Heart Rate
    if (hr != null) {
      if (hr > 130) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'High heart rate',
          message:
              'Heart rate is $hr bpm. If there is dizziness, chest pain, fainting, or severe palpitations, seek urgent care.',
        ));
      } else if (hr > 110) {
        alerts.add(_BuiltAlert(
          severity: 'medium',
          title: 'Elevated heart rate',
          message:
              'Heart rate is $hr bpm. Consider rest, hydration, and re-check. If persistent, consult a clinician.',
        ));
      } else if (hr < 45) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'Low heart rate',
          message:
              'Heart rate is $hr bpm. If there is fainting, weakness, or confusion, seek urgent evaluation.',
        ));
      } else if (hr < 55) {
        alerts.add(_BuiltAlert(
          severity: 'medium',
          title: 'Borderline low heart rate',
          message:
              'Heart rate is $hr bpm. Monitor symptoms. Some athletes can have low HR.',
        ));
      }
    }

    // Blood Pressure (simple ranges)
    if (sys != null && dia != null) {
      if (sys >= 180 || dia >= 120) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'Hypertensive crisis range',
          message:
              'Blood pressure is $sys/$dia mmHg. If there is headache, chest pain, shortness of breath, weakness, or vision changes, seek urgent care.',
        ));
      } else if (sys >= 140 || dia >= 90) {
        alerts.add(_BuiltAlert(
          severity: 'medium',
          title: 'High blood pressure',
          message:
              'Blood pressure is $sys/$dia mmHg. Monitor and consider medical advice if repeated.',
        ));
      } else if (sys < 90 || dia < 60) {
        alerts.add(_BuiltAlert(
          severity: 'medium',
          title: 'Low blood pressure',
          message:
              'Blood pressure is $sys/$dia mmHg. If there is dizziness or fainting, ensure hydration and consult a clinician if persistent.',
        ));
      }
    }

    // Glucose (mg/dL)
    if (glucose != null) {
      final g = glucose.round();
      if (g < 70) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'Low glucose (hypoglycemia range)',
          message:
              'Glucose is ~$g mg/dL. Consider a fast-acting carbohydrate if appropriate and re-check. Seek help if severe symptoms occur.',
        ));
      } else if (g >= 250) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'Very high glucose',
          message:
              'Glucose is ~$g mg/dL. If there is vomiting, dehydration, confusion, or rapid breathing, seek urgent care.',
        ));
      } else if (g >= 180) {
        alerts.add(_BuiltAlert(
          severity: 'medium',
          title: 'High glucose',
          message:
              'Glucose is ~$g mg/dL. Monitor and follow care plan if available.',
        ));
      }
    }

    // Temperature (C)
    if (temp != null) {
      if (temp >= 39.0) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'High fever',
          message:
              'Temperature is ${temp.toStringAsFixed(1)}°C. Ensure hydration and seek care if severe symptoms or persistent fever.',
        ));
      } else if (temp >= 37.8) {
        alerts.add(_BuiltAlert(
          severity: 'medium',
          title: 'Elevated temperature',
          message:
              'Temperature is ${temp.toStringAsFixed(1)}°C. Monitor and re-check.',
        ));
      } else if (temp <= 35.0) {
        alerts.add(_BuiltAlert(
          severity: 'high',
          title: 'Low body temperature',
          message:
              'Temperature is ${temp.toStringAsFixed(1)}°C. Warm the patient and seek urgent help if confusion or severe symptoms occur.',
        ));
      }
    }

    if (alerts.isEmpty) return;

    // write alerts with dedupe
    for (final a in alerts) {
      await _writeAlertIfNotDuplicate(
        patientId: patientId,
        built: a,
        now: now,
      );
    }
  }

  Future<void> _writeAlertIfNotDuplicate({
    required String patientId,
    required _BuiltAlert built,
    required DateTime now,
  }) async {
    final alertsRef =
        _db.collection('patients').doc(patientId).collection('alerts');

    final hash = _hashAlert(built);

    final lastSnap = await alertsRef
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastSnap.docs.isNotEmpty) {
      final last = lastSnap.docs.first.data();
      final lastHash = (last['hash'] ?? '').toString();
      final lastTs = (last['timestamp'] as Timestamp?)?.toDate();

      if (lastHash == hash && lastTs != null) {
        final diff = now.difference(lastTs);
        if (diff.inSeconds.abs() <= _dedupeWindow.inSeconds) {
          // same alert recently -> skip
          return;
        }
      }
    }

    await alertsRef.add({
      'message': '${built.title}: ${built.message}',
      'severity': built.severity, // high | medium | low
      'timestamp': Timestamp.fromDate(now),
      'hash': hash,
      'source': 'auto_vitals_insights',
    });
  }

  String _hashAlert(_BuiltAlert a) {
    final raw = '${a.severity}|${a.title}|${a.message}';
    return base64UrlEncode(utf8.encode(raw));
  }

  int? _tryInt(dynamic Function() getter) {
    try {
      final v = getter();
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }

  double? _tryDouble(dynamic Function() getter) {
    try {
      final v = getter();
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }

  bool? _tryBool(dynamic Function() getter) {
    try {
      final v = getter();
      if (v == null) return null;
      if (v is bool) return v;
      final s = v.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    } catch (_) {
      return null;
    }
  }

  Future<void> analyzeAndAlert(VitalSample s) async {}
}

class _BuiltAlert {
  final String severity;
  final String title;
  final String message;

  _BuiltAlert({
    required this.severity,
    required this.title,
    required this.message,
  });
}
