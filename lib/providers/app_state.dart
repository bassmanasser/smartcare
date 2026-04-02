import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare/models/medication.dart';

import '../config/dispatch_rules.dart';
import '../models/alert_item.dart';
import '../models/dispatch_decision.dart';
import '../models/doctor_note.dart';
import '../models/mood_record.dart';
import '../models/risk_assessment.dart';
import '../models/vital_sample.dart';
import '../services/ble_esp32_service.dart';
import '../services/dialog_service.dart';
import '../services/dispatch_engine.dart';
import '../services/glucose_api_service.dart';
import '../services/notification_service.dart';
import '../services/risk_engine.dart';

class AppState extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  final List<VitalSample> _vitals = [];
  List<VitalSample> get vitals => List.unmodifiable(_vitals);

  final List<AlertItem> _alerts = [];
  List<AlertItem> get alerts => List.unmodifiable(_alerts);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BleEsp32Service _bleService = BleEsp32Service();
  final RiskEngine _riskEngine = const RiskEngine();
  final DispatchEngine _dispatchEngine = const DispatchEngine();

  StreamSubscription? _bleSub;
  StreamSubscription? _connSub;

  bool isDeviceConnected = false;
  String deviceStatus = "Disconnected";
  bool _isScanning = false;
  String _activePatientId = "";

  final List<int> _irBuffer = [];
  final List<int> _ppgBuffer = [];

  double _lastPredictedGlucose = 0.0;
  double get lastPredictedGlucose => _lastPredictedGlucose;

  String glucoseStatusMsg = "Waiting for finger...";
  var doctors;

  RiskAssessment? _currentAssessment;
  RiskAssessment? get currentAssessment => _currentAssessment;

  DispatchDecision? _currentDispatch;
  DispatchDecision? get currentDispatch => _currentDispatch;

  String _caseStatus = DispatchRules.caseStatusStable;
  String get caseStatus => _caseStatus;

  String get recommendedSpecialty => _currentDispatch?.specialty ?? 'general';
  String get recommendedAction => _currentDispatch?.action.key ?? 'self_care';

  bool _arrhythmiaAbnormal = false;
  bool get arrhythmiaAbnormal => _arrhythmiaAbnormal;

  bool _respiratoryAbnormal = false;
  bool get respiratoryAbnormal => _respiratoryAbnormal;

  AppState() {
    _loadPreferences();
  }

  CollectionReference<Map<String, dynamic>> _vitalsRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('vitals');
  }

  CollectionReference<Map<String, dynamic>> _alertsRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('alerts');
  }

  CollectionReference<Map<String, dynamic>> _assessmentsRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('assessments');
  }

  CollectionReference<Map<String, dynamic>> _dispatchesRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('dispatches');
  }

  CollectionReference<Map<String, dynamic>> _timelineRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('timeline');
  }

  DocumentReference<Map<String, dynamic>> _caseCurrentRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('case').doc('current');
  }

  Future<void> _setBleStatus(String patientId, String status) async {
    if (patientId.isEmpty) return;
    try {
      await _db.collection('users').doc(patientId).set({
        "ble_status": status,
        "ble_last_seen": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ BLE status save error: $e");
    }
  }

  int _safeInt(dynamic v) {
    if (v is num && v.isFinite && !v.isNaN) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double _safeDouble(dynamic v) {
    if (v is num && v.isFinite && !v.isNaN) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  bool _safeBool(dynamic v) {
    if (v == true || v == 1 || v == "1") return true;
    return false;
  }

  void setArrhythmiaResult(bool abnormal) {
    _arrhythmiaAbnormal = abnormal;
    notifyListeners();
  }

  void setRespiratoryResult(bool abnormal) {
    _respiratoryAbnormal = abnormal;
    notifyListeners();
  }

  Future<void> connectDevice(String patientId) async {
    if (patientId.isEmpty) return;
    _activePatientId = patientId;

    if (isDeviceConnected || _isScanning) return;

    _isScanning = true;
    deviceStatus = "Scanning...";
    notifyListeners();

    try {
      await _bleService
          .scanAndConnect()
          .timeout(const Duration(seconds: 10));

      isDeviceConnected = true;
      deviceStatus = "Connected ✅";
      _isScanning = false;
      notifyListeners();

      await _connSub?.cancel();
      _connSub = _bleService.connectionStream.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          isDeviceConnected = true;
          deviceStatus = "Connected ✅";
          _setBleStatus(patientId, "online");
          notifyListeners();
        } else if (state == BluetoothConnectionState.disconnected) {
          isDeviceConnected = false;
          deviceStatus = "Disconnected ❌";
          _setBleStatus(patientId, "offline");
          NotificationService.instance.show("WARNING", "BLE Disconnected!");
          notifyListeners();
        }
      });

      await _setBleStatus(patientId, "online");

      await _bleSub?.cancel();
      _bleSub = _bleService.linesStream.listen((jsonStr) {
        _handleIncomingBleLine(patientId, jsonStr);
      });
    } catch (e) {
      isDeviceConnected = false;
      _isScanning = false;
      deviceStatus = "Device not found / Error";
      await _setBleStatus(patientId, "offline");
      notifyListeners();
    }
  }

  Future<void> _handleIncomingBleLine(String patientId, String jsonStr) async {
    try {
      final safeStr = jsonStr
          .trim()
          .replaceAll(':nan', ':null')
          .replaceAll(':NaN', ':null')
          .replaceAll(':Infinity', ':null')
          .replaceAll(':-Infinity', ':null');

      final data = jsonDecode(safeStr);

      final int hrVal = _safeInt(data['hr']);
      final int spo2Val = _safeInt(data['spo2']);
      final int sysVal = _safeInt(data['sys'] ?? data['systolic']);
      final int diaVal = _safeInt(data['dia'] ?? data['diastolic']);
      final double tempVal = _safeDouble(data['temp'] ?? data['temperature']);
      final bool fallVal = _safeBool(data['fall'] ?? data['fallFlag']);
      final int currentIr = _safeInt(data['ir'] ?? data['IR']);
      final int currentPpg =
          _safeInt(data['ppg'] ?? data['raw_ppg'] ?? data['ppg_ir']);

      await _handleLiveGlucoseCollection(currentIr);
      _handlePpgCollection(currentPpg);

      final double hardwareGlucose = _safeDouble(data['glucose']);
      final double finalGlucose =
          (_lastPredictedGlucose > 0) ? _lastPredictedGlucose : hardwareGlucose;

      final sample = VitalSample(
        id: '',
        patientId: patientId,
        hr: hrVal,
        spo2: spo2Val,
        sys: sysVal,
        dia: diaVal,
        glucose: finalGlucose,
        temperature: tempVal,
        fallFlag: fallVal,
        timestamp: DateTime.now(),
      );

      await pushVital(sample);
    } catch (e) {
      debugPrint("❌ BLE Parse Error: $e");
    }
  }

  Future<void> _handleLiveGlucoseCollection(int currentIr) async {
    if (currentIr > 50000) {
      _irBuffer.add(currentIr);
      glucoseStatusMsg = "Collecting (${_irBuffer.length}/20)";
      notifyListeners();

      if (_irBuffer.length >= 20) {
        final payload = List<int>.from(_irBuffer);
        _irBuffer.clear();
        glucoseStatusMsg = "Calculating API...";
        notifyListeners();

        try {
          final result = await GlucoseApiService.predictGlucose(payload);
          _lastPredictedGlucose = result;
          glucoseStatusMsg = "Done!";
        } catch (e) {
          glucoseStatusMsg = "API Error!";
          debugPrint("❌ Glucose API Error: $e");
        }
        notifyListeners();
      }
    } else {
      if (_irBuffer.isNotEmpty) {
        _irBuffer.clear();
      }
      glucoseStatusMsg = "Waiting for finger...";
      notifyListeners();
    }
  }

  void _handlePpgCollection(int currentPpg) {
    if (currentPpg > 0) {
      _ppgBuffer.add(currentPpg);
      if (_ppgBuffer.length > 1200) {
        _ppgBuffer.removeAt(0);
      }
    }
  }

  Future<void> pushVital(VitalSample sample) async {
    _vitals.add(sample);
    if (_vitals.length > 50) {
      _vitals.removeAt(0);
    }

    notifyListeners();

    final json = sample.toJson();
    json['ppg_values'] = List<int>.from(_ppgBuffer);
    json['ir_values'] = List<int>.from(_irBuffer);
    json['timestamp'] = FieldValue.serverTimestamp();

    if (json['temperature'] is double &&
        (json['temperature'] as double).isNaN) {
      json['temperature'] = 0.0;
    }

    if (json['glucose'] is double && (json['glucose'] as double).isNaN) {
      json['glucose'] = 0.0;
    }

    try {
      await _vitalsRef(sample.patientId).add(json);
      await _addTimelineEvent(
        patientId: sample.patientId,
        type: 'vital_saved',
        title: 'Vital reading saved',
        data: {
          'hr': sample.hr,
          'spo2': sample.spo2,
          'sys': sample.sys,
          'dia': sample.dia,
          'temperature': sample.temperature,
          'glucose': sample.glucose,
          'fallFlag': sample.fallFlag,
        },
      );
    } catch (e) {
      debugPrint("❌ Save Error: $e");
    }

    await _checkVitalsForAlerts(sample);
    await analyzePatientCase(sample.patientId, sample);
    notifyListeners();
  }

  Future<void> analyzePatientCase(String patientId, VitalSample sample) async {
    final history = _vitals.length <= 1
        ? <VitalSample>[]
        : List<VitalSample>.from(_vitals.sublist(0, _vitals.length - 1));

    final assessment = _riskEngine.assess(
      patientId: patientId,
      latest: sample,
      history: history,
      arrhythmiaAbnormal: _arrhythmiaAbnormal,
      respiratoryAbnormal: _respiratoryAbnormal,
    );

    final savedAssessment = await saveRiskAssessment(assessment);

    final dispatch = _dispatchEngine.decide(
      patientId: patientId,
      assessment: savedAssessment,
      arrhythmiaAbnormal: _arrhythmiaAbnormal,
      respiratoryAbnormal: _respiratoryAbnormal,
    );

    final savedDispatch = await saveDispatchDecision(dispatch);

    _currentAssessment = savedAssessment;
    _currentDispatch = savedDispatch;
    _caseStatus = _mapRiskToCaseStatus(savedAssessment.riskLevel);

    await updateCurrentCase(
      patientId: patientId,
      assessment: savedAssessment,
      decision: savedDispatch,
    );

    await _handleRiskNotifications(savedAssessment, savedDispatch);
  }

  Future<RiskAssessment> saveRiskAssessment(RiskAssessment assessment) async {
    final json = assessment.toJson();
    json['createdAt'] = FieldValue.serverTimestamp();

    try {
      final ref = await _assessmentsRef(assessment.patientId).add(json);

      await _addTimelineEvent(
        patientId: assessment.patientId,
        type: 'risk_assessment',
        title: 'Risk assessment generated',
        data: {
          'riskLevel': assessment.riskLevel.key,
          'score': assessment.score,
          'reasons': assessment.reasons,
          'triggeredVitals': assessment.triggeredVitals,
        },
      );

      return assessment.copyWith(id: ref.id);
    } catch (e) {
      debugPrint("❌ Assessment Save Error: $e");
      return assessment;
    }
  }

  Future<DispatchDecision> saveDispatchDecision(
    DispatchDecision decision,
  ) async {
    final json = decision.toJson();
    json['createdAt'] = FieldValue.serverTimestamp();

    try {
      final ref = await _dispatchesRef(decision.patientId).add(json);

      await _addTimelineEvent(
        patientId: decision.patientId,
        type: 'dispatch_decision',
        title: 'Dispatch decision generated',
        data: {
          'specialty': decision.specialty,
          'urgency': decision.urgency.key,
          'action': decision.action.key,
          'explanation': decision.explanation,
        },
      );

      return decision.copyWith(id: ref.id);
    } catch (e) {
      debugPrint("❌ Dispatch Save Error: $e");
      return decision;
    }
  }

  Future<void> updateCurrentCase({
    required String patientId,
    required RiskAssessment assessment,
    required DispatchDecision decision,
  }) async {
    try {
      await _caseCurrentRef(patientId).set({
        'patientId': patientId,
        'latestRiskLevel': assessment.riskLevel.key,
        'riskScore': assessment.score,
        'reasons': assessment.reasons,
        'triggeredVitals': assessment.triggeredVitals,
        'latestUrgency': decision.urgency.key,
        'latestSpecialty': decision.specialty,
        'latestAction': decision.action.key,
        'latestExplanation': decision.explanation,
        'caseStatus': _mapRiskToCaseStatus(assessment.riskLevel),
        'activeAlertsCount': _alerts.length,
        'arrhythmiaAbnormal': _arrhythmiaAbnormal,
        'respiratoryAbnormal': _respiratoryAbnormal,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Current Case Update Error: $e");
    }
  }

  Future<void> _addTimelineEvent({
    required String patientId,
    required String type,
    required String title,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _timelineRef(patientId).add({
        'type': type,
        'title': title,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Timeline Save Error: $e");
    }
  }

  Future<void> _checkVitalsForAlerts(VitalSample s) async {
    if (s.fallFlag) {
      await addAlert(
        AlertItem(
          id: '',
          patientId: s.patientId,
          type: 'FALL DETECTED',
          message: 'Patient has fallen!',
          severity: 'critical',
          timestamp: DateTime.now(),
        ),
      );
      NotificationService.instance.show("EMERGENCY", "Fall Detected!");
    }

    DialogService.showGlucoseAlert(s.glucose);

    if (s.glucose > DispatchRules.highGlucoseThreshold) {
      await addAlert(
        AlertItem(
          id: '',
          patientId: s.patientId,
          type: 'High Glucose',
          message: 'Glucose: ${s.glucose.toInt()} mg/dL',
          severity: s.glucose >= DispatchRules.criticalHighGlucoseThreshold
              ? 'critical'
              : 'high',
          timestamp: DateTime.now(),
        ),
      );
    } else if (s.glucose < DispatchRules.lowGlucoseThreshold && s.glucose > 0) {
      await addAlert(
        AlertItem(
          id: '',
          patientId: s.patientId,
          type: 'Low Glucose',
          message: 'Glucose: ${s.glucose.toInt()} mg/dL',
          severity: s.glucose <= DispatchRules.criticalLowGlucoseThreshold
              ? 'critical'
              : 'high',
          timestamp: DateTime.now(),
        ),
      );
    }

    if (s.temperature > DispatchRules.feverThreshold) {
      await addAlert(
        AlertItem(
          id: '',
          patientId: s.patientId,
          type: 'Fever',
          message: 'Temp: ${s.temperature.toStringAsFixed(1)}°C',
          severity: s.temperature >= DispatchRules.criticalFeverThreshold
              ? 'high'
              : 'medium',
          timestamp: DateTime.now(),
        ),
      );
    }

    if (s.spo2 < DispatchRules.lowSpo2Threshold && s.spo2 > 0) {
      await addAlert(
        AlertItem(
          id: '',
          patientId: s.patientId,
          type: 'Low Oxygen',
          message: 'SpO2: ${s.spo2}%',
          severity: s.spo2 < DispatchRules.criticalSpo2Threshold
              ? 'critical'
              : 'high',
          timestamp: DateTime.now(),
        ),
      );
    }

    if ((s.hr > DispatchRules.highHrThreshold) ||
        (s.hr > 0 && s.hr < DispatchRules.lowHrThreshold)) {
      await addAlert(
        AlertItem(
          id: '',
          patientId: s.patientId,
          type: 'Abnormal Heart Rate',
          message: 'HR: ${s.hr} bpm',
          severity: (s.hr >= DispatchRules.criticalHighHrThreshold ||
                  (s.hr > 0 && s.hr <= DispatchRules.criticalLowHrThreshold))
              ? 'critical'
              : 'medium',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _handleRiskNotifications(
    RiskAssessment assessment,
    DispatchDecision decision,
  ) async {
    if (assessment.riskLevel == RiskLevel.emergency) {
      NotificationService.instance.show(
        "EMERGENCY",
        "Emergency case detected. Route: ${decision.specialty}",
      );
      return;
    }

    if (assessment.riskLevel == RiskLevel.highRisk) {
      NotificationService.instance.show(
        "HIGH RISK",
        "Urgent medical review recommended.",
      );
      return;
    }

    if (assessment.riskLevel == RiskLevel.attention) {
      NotificationService.instance.show(
        "ATTENTION",
        "Doctor consultation is recommended.",
      );
    }
  }

  String _mapRiskToCaseStatus(RiskLevel level) {
    switch (level) {
      case RiskLevel.normal:
        return DispatchRules.caseStatusStable;
      case RiskLevel.attention:
        return DispatchRules.caseStatusAttention;
      case RiskLevel.highRisk:
        return DispatchRules.caseStatusHighRisk;
      case RiskLevel.emergency:
        return DispatchRules.caseStatusEmergency;
    }
  }

  Future<void> addAlert(AlertItem alert) async {
    if (_alerts.isNotEmpty) {
      final last = _alerts.first;
      if (last.type == alert.type &&
          alert.timestamp.difference(last.timestamp).inMinutes < 1) {
        return;
      }
    }

    _alerts.insert(0, alert);
    notifyListeners();

    final json = alert.toJson();
    json['timestamp'] = FieldValue.serverTimestamp();

    try {
      await _alertsRef(alert.patientId).add(json);

      await _addTimelineEvent(
        patientId: alert.patientId,
        type: 'alert_generated',
        title: alert.type,
        data: {
          'message': alert.message,
          'severity': alert.severity,
        },
      );
    } catch (e) {
      debugPrint("❌ Alert Save Error: $e");
    }
  }

  Future<void> disconnectDevice() async {
    await _bleSub?.cancel();
    await _connSub?.cancel();
    await _bleService.disconnect();

    isDeviceConnected = false;
    deviceStatus = "Disconnected";
    _isScanning = false;

    await _setBleStatus(_activePatientId, "offline");
    notifyListeners();
  }

  Future<void> fetchHistory(String patientId) async {
    if (patientId.isEmpty) return;

    try {
      final q = await _vitalsRef(patientId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _vitals.clear();
      for (final doc in q.docs) {
        _vitals.add(VitalSample.fromJson(doc.data(), doc.id));
      }
      _vitals.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      await fetchAlerts(patientId);
      await fetchCurrentCase(patientId);

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Fetch History Error: $e");
    }
  }

  Future<void> fetchAlerts(String patientId) async {
    if (patientId.isEmpty) return;

    try {
      final q = await _alertsRef(patientId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      _alerts.clear();
      for (final doc in q.docs) {
        _alerts.add(AlertItem.fromJson(doc.data(), doc.id));
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Fetch Alerts Error: $e");
    }
  }

  Future<void> fetchCurrentCase(String patientId) async {
    if (patientId.isEmpty) return;

    try {
      final doc = await _caseCurrentRef(patientId).get();
      final data = doc.data();
      if (data == null) return;

      _caseStatus =
          (data['caseStatus'] ?? DispatchRules.caseStatusStable).toString();

      _currentAssessment = RiskAssessment(
        id: '',
        patientId: patientId,
        riskLevel: RiskLevelX.fromString(data['latestRiskLevel']?.toString()),
        score: (data['riskScore'] as num?)?.toInt() ?? 0,
        reasons: List<String>.from(data['reasons'] ?? const []),
        triggeredVitals: List<String>.from(data['triggeredVitals'] ?? const []),
        createdAt: DateTime.now(),
      );

      _currentDispatch = DispatchDecision(
        id: '',
        patientId: patientId,
        specialty: (data['latestSpecialty'] ?? 'general').toString(),
        urgency: DispatchUrgencyX.fromString(data['latestUrgency']?.toString()),
        action: DispatchActionX.fromString(data['latestAction']?.toString()),
        explanation: (data['latestExplanation'] ?? '').toString(),
        sourceAssessmentId: null,
        createdAt: DateTime.now(),
      );

      _arrhythmiaAbnormal = data['arrhythmiaAbnormal'] == true;
      _respiratoryAbnormal = data['respiratoryAbnormal'] == true;

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Fetch Current Case Error: $e");
    }
  }

  void changeLanguage(String code) async {
    _currentLocale = Locale(code);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('lang') ?? 'en';
    _currentLocale = Locale(lang);
    notifyListeners();
  }

  get moodRecords => null;
  get patients => null;

  Future<void> registerPatient(dynamic p) async {
    await _db.collection('users').doc(p.id).set(p.toJson());
  }

  Future<void> registerDoctor(dynamic d) async {
    await _db.collection('users').doc(d.id).set(d.toJson());
  }

  Future<void> addMood(MoodRecord rec) async {}

  getVitalsForPatient(id) {}

  void addDoctorNote(DoctorNote newNote) {}

  getNotesForPatient(String id) {}

  Future<void> addMedication(Medication result, Medication patientId) async {}

  getMedicationsForPatient(String patientId) {}

  getAlertsForPatient(String id) {}

  getMoodsForPatient(String id) {}

  VitalSample? getLatestVitals(String id) {
    if (_vitals.isEmpty) return null;
    return _vitals.last;
  }

  Future<void> fetchDoctorNotes(String id) async {}

  Future<void> setLocale(Locale locale) async {}
}