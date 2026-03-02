import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// لازم نعمل Handler للخدمة
class BleFgTaskHandler extends TaskHandler {
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _reconnectTimer;

  late String _patientId;
  late String _deviceId; // id or remoteId string

  BluetoothDevice? _device;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // مهم: Initialize Firebase داخل الـ background isolate
    await Firebase.initializeApp();

    final data = await FlutterForegroundTask.getData<Map>(key: 'bleData');
    _patientId = (data?['patientId'] ?? '').toString();
    _deviceId  = (data?['deviceId'] ?? '').toString();

    // deviceId هنا هو remoteId اللي بتجيبيه من device.remoteId.str
    // FlutterBluePlus بيديك BluetoothDevice من remoteId:
    _device = BluetoothDevice.fromId(_deviceId);

    // ابدأ الاتصال + الليسنر
    await _safeConnect();
    _listenConnection();
  }

  void _listenConnection() {
    final device = _device;
    if (device == null) return;

    _connSub?.cancel();
    _connSub = device.connectionState.listen((state) async {
      // تحديث إشعار الخدمة
      FlutterForegroundTask.updateService(
        notificationTitle: 'SmartCare BLE Monitor',
        notificationText: 'BLE state: $state',
      );

      if (state == BluetoothConnectionState.connected) {
        await _setOnline();
        _stopReconnectLoop();
      } else if (state == BluetoothConnectionState.disconnected) {
        await _setOffline();
        _startReconnectLoop();
      }
    });
  }

  Future<void> _setOnline() async {
    if (_patientId.isEmpty) return;
    await FirebaseFirestore.instance.collection('patients').doc(_patientId).set({
      "status": "online",
      "last_seen": FieldValue.serverTimestamp(),
      "device_id": _deviceId,
      "last_disconnect_reason": null,
    }, SetOptions(merge: true));
  }

  Future<void> _setOffline() async {
    if (_patientId.isEmpty) return;
    await FirebaseFirestore.instance.collection('patients').doc(_patientId).set({
      "status": "offline",
      "last_seen": FieldValue.serverTimestamp(),
      "device_id": _deviceId,
      "last_disconnect_reason": "ble_disconnected",
    }, SetOptions(merge: true));
  }

  void _startReconnectLoop() {
    _reconnectTimer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      await _safeConnect();
    });
  }

  void _stopReconnectLoop() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _safeConnect() async {
    final device = _device;
    if (device == null) return;

    try {
      await device.connect(
        autoConnect: true,
        timeout: const Duration(seconds: 8),
      );
    } catch (_) {
      // طبيعي يفشل لو بعيد
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // ممكن تسيبيها فاضية
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _connSub?.cancel();
    _stopReconnectLoop();
  }
}
