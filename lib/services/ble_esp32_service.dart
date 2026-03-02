import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleEsp32Service {
  final String deviceNameHint = "SmartCare_Watch";

  final Guid serviceUuid = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid charUuid = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

  BluetoothDevice? _device;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  final _linesCtrl = StreamController<String>.broadcast();
  Stream<String> get linesStream => _linesCtrl.stream;

  final _connCtrl = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStream => _connCtrl.stream;

  final StringBuffer _rxBuffer = StringBuffer();

  Timer? _reconnectTimer;

  Future<bool> _ensurePermissions() async {
    final perms = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    for (final p in perms) {
      final s = await p.request();
      if (!s.isGranted) return false;
    }
    return true;
  }

  Future<void> scanAndConnect() async {
    final ok = await _ensurePermissions();
    if (!ok) throw Exception("Bluetooth permissions not granted.");

    await FlutterBluePlus.stopScan();
    _device = null;

    final completer = Completer<void>();

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final name = r.device.platformName;
        if (name == deviceNameHint) {
          debugPrint("✅ Found device: $name");
          _device = r.device;

          await FlutterBluePlus.stopScan();
          await _scanSub?.cancel();

          try {
            await _connectToDevice(r.device);
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            if (!completer.isCompleted) completer.completeError(e);
          }
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    return completer.future;
  }

  String _sanitizeJson(String s) {
    var out = s.trim();

    out = out
        .replaceAll(':nan', ':null')
        .replaceAll(':NaN', ':null')
        .replaceAll(':Infinity', ':null')
        .replaceAll(':-Infinity', ':null');

    out = out.replaceAll(RegExp(r'[\u0000-\u001F]'), '');

    return out.trim();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;
    await device.connect(timeout: const Duration(seconds: 10));

    _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      _connCtrl.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _startAutoReconnect();
      } else if (state == BluetoothConnectionState.connected) {
        _stopAutoReconnect();
      }
    });

    debugPrint("✅ Connected! Discovering Services...");
    try {
      await device.requestMtu(512);
    } catch (_) {}

    List<BluetoothService> services = await device.discoverServices();
    bool charFound = false;

    for (var s in services) {
      if (s.uuid == serviceUuid) {
        for (var c in s.characteristics) {
          if (c.uuid == charUuid) {
            debugPrint("✅ Characteristic Found! Listening for data...");
            await c.setNotifyValue(true);

            c.lastValueStream.listen((value) {
              try {
                final chunk = utf8.decode(value, allowMalformed: true);
                if (chunk.isEmpty) return;

                _rxBuffer.write(chunk);
                String currentBuffer = _rxBuffer.toString();

                if (currentBuffer.contains('{') && currentBuffer.contains('}')) {
                  int startIndex = currentBuffer.indexOf('{');
                  int endIndex = currentBuffer.lastIndexOf('}');

                  if (endIndex > startIndex) {
                    String fullMessage =
                        currentBuffer.substring(startIndex, endIndex + 1);

                    String sanitized = _sanitizeJson(fullMessage);
                    if (sanitized.isNotEmpty) {
                      debugPrint("📥 Received JSON: $sanitized");
                      _linesCtrl.add(sanitized);
                    }

                    _rxBuffer.clear();
                    String remaining = currentBuffer.substring(endIndex + 1);
                    _rxBuffer.write(remaining);
                  }
                }
              } catch (e) {
                debugPrint("❌ Parsing Error: $e");
              }
            });

            charFound = true;
            break;
          }
        }
      }
    }
    if (!charFound) throw Exception("Service not found on device.");
  }

  void _startAutoReconnect() {
    _reconnectTimer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_device == null) return;
      try {
        await _device!.connect(timeout: const Duration(seconds: 8));
      } catch (_) {}
    });
  }

  void _stopAutoReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> disconnect() async {
    await _scanSub?.cancel();
    await _connSub?.cancel();
    _stopAutoReconnect();
    if (_device != null) await _device!.disconnect();
    _device = null;
  }

  void dispose() {
    disconnect();
    _linesCtrl.close();
    _connCtrl.close();
  }
}
