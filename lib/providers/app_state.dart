import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartcare/models/medication.dart';

import '../models/vital_sample.dart';
import '../models/alert_item.dart';
import '../models/doctor_note.dart';
import '../models/mood_record.dart';

import '../services/ble_esp32_service.dart';
import '../services/notification_service.dart';
import '../services/dialog_service.dart';

import '../services/glucose_api_service.dart';

class AppState extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  final List<VitalSample> _vitals = [];
  List<VitalSample> get vitals => List.unmodifiable(_vitals);

  final List<AlertItem> _alerts = [];
  List<AlertItem> get alerts => List.unmodifiable(_alerts);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BleEsp32Service _bleService = BleEsp32Service();
  StreamSubscription? _bleSub;
  StreamSubscription? _connSub;

  bool isDeviceConnected = false;
  String deviceStatus = "Disconnected";
  bool _isScanning = false;

  String _activePatientId = "";

  // ==========================================================
  // 🔥 مصفوفات تجميع البيانات للـ Machine Learning
  // ==========================================================
  final List<int> _irBuffer = [];
  final List<int> _ppgBuffer = [];
  
  double _lastPredictedGlucose = 0.0;
  double get lastPredictedGlucose => _lastPredictedGlucose;

  // متغيّر لعرض حالة السكر لحظة بلحظة على الشاشة
  String glucoseStatusMsg = "Waiting for finger...";

  var doctors;

  AppState() {
    _loadPreferences();
  }

  CollectionReference<Map<String, dynamic>> _vitalsRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('vitals');
  }

  CollectionReference<Map<String, dynamic>> _alertsRef(String patientId) {
    return _db.collection('users').doc(patientId).collection('alerts');
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

  Future<void> connectDevice(String patientId) async {
    if (patientId.isEmpty) return;
    _activePatientId = patientId;

    if (isDeviceConnected || _isScanning) return;

    _isScanning = true;
    deviceStatus = "Scanning...";
    notifyListeners();

    try {
      await _bleService.scanAndConnect().timeout(const Duration(seconds: 10));
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

      _setBleStatus(patientId, "online");

      await _bleSub?.cancel();
      _bleSub = _bleService.linesStream.listen((jsonStr) {
        try {
          final safeStr = jsonStr.trim()
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
          final int currentPpg = _safeInt(data['ppg'] ?? data['raw_ppg'] ?? data['ppg_ir']);

          // ==========================================================
          // 🔥 تحديث الشاشة لحظة بلحظة بحالة سحب قراءات السكر
          // ==========================================================
          if (currentIr > 50000) { 
            _irBuffer.add(currentIr);
            
            glucoseStatusMsg = "Collecting (${_irBuffer.length}/20)";
            notifyListeners();

            if (_irBuffer.length >= 20) {
              final payload = List<int>.from(_irBuffer);
              _irBuffer.clear();

              glucoseStatusMsg = "Calculating API...";
              notifyListeners();
              
              GlucoseApiService.predictGlucose(payload).then((result) {
                _lastPredictedGlucose = result;
                glucoseStatusMsg = "Done!";
                notifyListeners(); 
              }).catchError((e) {
                glucoseStatusMsg = "API Error!";
                debugPrint("❌ Glucose API Error: $e");
                notifyListeners();
              });
            }
          } else {
            if (_irBuffer.isNotEmpty) {
              _irBuffer.clear();
            }
            glucoseStatusMsg = "Waiting for finger...";
            notifyListeners();
          }

          // ==========================================================
          // 🔥 تجميع الـ PPG عشان الـ Arrhythmia (مطلوب 10 ثواني = 1000 قراءة)
          // ==========================================================
          if (currentPpg > 0) {
            _ppgBuffer.add(currentPpg);
            if (_ppgBuffer.length > 1200) _ppgBuffer.removeAt(0); // ✅ تم التعديل لـ 1200 لتكفي الموديل
          }

          double hardwareGlucose = _safeDouble(data['glucose']);
          double finalGlucose = (_lastPredictedGlucose > 0) ? _lastPredictedGlucose : hardwareGlucose;

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

          pushVital(sample);

        } catch (e) {
          debugPrint("❌ BLE Parse Error: $e");
        }
      });
    } catch (e) {
      isDeviceConnected = false;
      _isScanning = false;
      deviceStatus = "Device not found / Error";
      _setBleStatus(patientId, "offline");
      notifyListeners();
    }
  }

  void pushVital(VitalSample sample) {
    _vitals.add(sample);
    if (_vitals.length > 50) _vitals.removeAt(0);

    _checkVitalsForAlerts(sample);

    notifyListeners();

    final json = sample.toJson();
    json['ppg_values'] = List<int>.from(_ppgBuffer);
    json['ir_values'] = List<int>.from(_irBuffer);
    json['timestamp'] = FieldValue.serverTimestamp();

    if (json['temperature'] is double && (json['temperature'] as double).isNaN) json['temperature'] = 0.0;
    if (json['glucose'] is double && (json['glucose'] as double).isNaN) json['glucose'] = 0.0;

    _vitalsRef(sample.patientId).add(json).catchError((e) => debugPrint("❌ Save Error: $e"));
  }

  void _checkVitalsForAlerts(VitalSample s) {
    if (s.fallFlag) {
      addAlert(AlertItem(id: '', patientId: s.patientId, type: 'FALL DETECTED', message: 'Patient has fallen!', severity: 'critical', timestamp: DateTime.now()));
      NotificationService.instance.show("EMERGENCY", "Fall Detected!");
    }
    DialogService.showGlucoseAlert(s.glucose);
    if (s.glucose > 180) {
      addAlert(AlertItem(id: '', patientId: s.patientId, type: 'High Glucose', message: 'Glucose: ${s.glucose.toInt()} mg/dL', severity: 'high', timestamp: DateTime.now()));
    } else if (s.glucose < 70 && s.glucose > 0) {
      addAlert(AlertItem(id: '', patientId: s.patientId, type: 'Low Glucose', message: 'Glucose: ${s.glucose.toInt()} mg/dL', severity: 'high', timestamp: DateTime.now()));
    }
    if (s.temperature > 38.0) {
      addAlert(AlertItem(id: '', patientId: s.patientId, type: 'Fever', message: 'Temp: ${s.temperature.toStringAsFixed(1)}°C', severity: 'medium', timestamp: DateTime.now()));
    }
    if (s.spo2 < 92 && s.spo2 > 0) {
      addAlert(AlertItem(id: '', patientId: s.patientId, type: 'Low Oxygen', message: 'SpO2: ${s.spo2}%', severity: 'high', timestamp: DateTime.now()));
    }
  }

  Future<void> addAlert(AlertItem alert) async {
    if (_alerts.isNotEmpty) {
      final last = _alerts.first;
      if (last.type == alert.type && alert.timestamp.difference(last.timestamp).inMinutes < 1) return;
    }
    _alerts.insert(0, alert);
    notifyListeners();
    final json = alert.toJson();
    json['timestamp'] = FieldValue.serverTimestamp();
    try { await _alertsRef(alert.patientId).add(json); } catch (e) { debugPrint("❌ Alert Save Error: $e"); }
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
      final q = await _vitalsRef(patientId).orderBy('timestamp', descending: true).limit(50).get();
      _vitals.clear();
      for (var doc in q.docs) { _vitals.add(VitalSample.fromJson(doc.data(), doc.id)); }
      _vitals.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await fetchAlerts(patientId);
      notifyListeners();
    } catch (e) {}
  }

  Future<void> fetchAlerts(String patientId) async {
    if (patientId.isEmpty) return;
    try {
      final q = await _alertsRef(patientId).orderBy('timestamp', descending: true).limit(20).get();
      _alerts.clear();
      for (var doc in q.docs) { _alerts.add(AlertItem.fromJson(doc.data(), doc.id)); }
      notifyListeners();
    } catch (e) {}
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
  Future<void> registerPatient(dynamic p) async { await _db.collection('users').doc(p.id).set(p.toJson()); }
  Future<void> registerDoctor(dynamic d) async { await _db.collection('users').doc(d.id).set(d.toJson()); }
  Future<void> addMood(MoodRecord rec) async {}
  getVitalsForPatient(id) {}
  void addDoctorNote(DoctorNote newNote) {}
  getNotesForPatient(String id) {}
  Future<void> addMedication(Medication result, Medication patientId) async {}
  getMedicationsForPatient(String patientId) {}
  getAlertsForPatient(String id) {}
  getMoodsForPatient(String id) {}
  VitalSample? getLatestVitals(String id) {}
}