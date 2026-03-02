import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/constants.dart';

class ArrhythmiaCheckScreen extends StatefulWidget {
  final String patientId;
  const ArrhythmiaCheckScreen({super.key, required this.patientId});

  @override
  State<ArrhythmiaCheckScreen> createState() => _ArrhythmiaCheckScreenState();
}

class _ArrhythmiaCheckScreenState extends State<ArrhythmiaCheckScreen> {
  // ✅ المسار الصحيح للسيرفر
  static const String _baseUrl = 'https://mariam2112-smartheart-api.hf.space';
  static const String _endpoint = '/predict';

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<List<num>> _getLatestPpg() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .collection('vitals')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) {
        final data = qs.docs.first.data();

        final raw = data['ppg_values'] ?? data['ppg'] ?? data['ppgValues'];
        if (raw is List) {
          final out = <num>[];
          for (final v in raw) {
            if (v is num) out.add(v);
          }
          return out;
        }
      }
    } catch (_) {
      // ignore and fallback below
    }

    final qs = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('vitals')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return [];

    final data = qs.docs.first.data();

    final raw = data['ppg_values'] ?? data['ppg'] ?? data['ppgValues'];
    if (raw is! List) return [];

    final out = <num>[];
    for (final v in raw) {
      if (v is num) out.add(v);
    }
    return out;
  }

  Future<Map<String, dynamic>> _callAi({
    required int fs,
    required List<num> ppg,
  }) async {
    final url = Uri.parse('$_baseUrl$_endpoint');

    // 👇 التعديل هنا: تم جعل المتغيرات مطابقة لكود البايثون 100% 👇
    final body = {
      "fs": fs,
      "ppg": ppg, 
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('AI API Error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<void> _saveResult(Map<String, dynamic> result, int fs, int count) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('arrhythmia_results')
        .add({
      "result": result,
      "fs": fs,
      "ppgCount": count,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _runCheck() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please login first.");

      const fs = 100; 
      final ppg = await _getLatestPpg();
      if (ppg.isEmpty) {
        throw Exception(
          "No PPG data found.\nMake sure you store raw PPG array in users/{uid}/vitals (field: ppg_values).",
        );
      }

      // إرسال البيانات للـ API
      final result = await _callAi(fs: fs, ppg: ppg);
      await _saveResult(result, fs, ppg.length);

      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pretty = _result == null ? null : const JsonEncoder.withIndent('  ').convert(_result);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrhythmia Check'),
        backgroundColor: PETROL_DARK,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _runCheck,
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text('Run Arrhythmia Check', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),

            if (_error != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (pretty != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(pretty),
                ),
              )
            else
              const Expanded(
                child: Center(child: Text("Press the button to analyze the latest PPG.")),
              ),
          ],
        ),
      ),
    );
  }
}