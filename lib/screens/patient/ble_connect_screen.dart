import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // لم نعد نحتاجه هنا مباشرة
import '../../utils/constants.dart';
import '../../services/ble_esp32_service.dart';

class BleConnectScreen extends StatefulWidget {
  const BleConnectScreen({super.key});

  @override
  State<BleConnectScreen> createState() => _BleConnectScreenState();
}

class _BleConnectScreenState extends State<BleConnectScreen> {

  final ble = BleEsp32Service();

  StreamSubscription<String>? _sub;
  String lastLine = "";
  String status = "Not connected";

  @override
  void initState() {
    super.initState();

    // ✅ 2. التعديل: الاستماع للبيانات فقط
    _sub = ble.linesStream.listen((line) {
      // validate json
      try {
        jsonDecode(line);
        setState(() => lastLine = line);
      } catch (_) {
        setState(() => lastLine = "Non-JSON: $line");
      }
      // debug
      debugPrint("FROM ESP32: $line");
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    // ✅ 3. التعديل: استخدام disconnect بدلاً من dispose
    ble.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      setState(() => status = "Scanning...");
      await ble.scanAndConnect();
      // تحديث الحالة يدوياً عند النجاح
      setState(() => status = "✅ Connected");
    } catch (e) {
      setState(() => status = "Error: $e");
    }
  }

  Future<void> _disconnect() async {
    await ble.disconnect();
    setState(() => status = "❌ Disconnected");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 BLE Test"), backgroundColor: PETROL_DARK),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: $status", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: PETROL,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
              ),
              icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
              label: const Text("Scan & Connect", style: TextStyle(color: Colors.white)),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
              label: const Text("Disconnect", style: TextStyle(color: Colors.red)),
            ),
            
            const Divider(height: 28),
            const Text("Last Data Received:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: SingleChildScrollView(
                  child: Text(
                    lastLine.isEmpty ? "Waiting for data..." : lastLine,
                    style: const TextStyle(fontFamily: 'Courier'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}