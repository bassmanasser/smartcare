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

class _ArrhythmiaCheckScreenState extends State<ArrhythmiaCheckScreen>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://mariam2112-smartheart-api.hf.space';
  static const String _endpoint = '/predict';

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<List<num>> _getLatestPpg() async {
    for (final orderField in ['timestamp', 'createdAt']) {
      try {
        final qs = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.patientId)
            .collection('vitals')
            .orderBy(orderField, descending: true)
            .limit(1)
            .get();

        if (qs.docs.isNotEmpty) {
          final data = qs.docs.first.data();
          final raw = data['ppg_values'] ?? data['ppg'] ?? data['ppgValues'];
          if (raw is List && raw.isNotEmpty) {
            return raw.whereType<num>().toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  Future<Map<String, dynamic>> _callAi({
    required int fs,
    required List<num> ppg,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fs': fs, 'ppg': ppg}),
    );
    if (res.statusCode != 200) {
      throw Exception('AI API Error ${res.statusCode}: ${res.body}');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<void> _saveResult(
      Map<String, dynamic> result, int fs, int count) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('arrhythmia_results')
        .add({
      'result': result,
      'fs': fs,
      'ppgCount': count,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _runCheck() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('Please login first.');
      }
      const fs = 100;
      final ppg = await _getLatestPpg();
      if (ppg.isEmpty) {
        throw Exception(
          'No PPG data found. Make sure the device is connected and has sent at least one reading.',
        );
      }
      final result = await _callAi(fs: fs, ppg: ppg);
      await _saveResult(result, fs, ppg.length);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  String _rhythmLabel(Map<String, dynamic> r) {
    final raw = (r['rhythm'] ?? r['label'] ?? r['prediction'] ??
            r['class'] ?? r['result'] ?? '')
        .toString()
        .toLowerCase();
    if (raw.isEmpty) return 'Unknown';
    if (raw.contains('normal') || raw.contains('sinus')) return 'Normal Sinus';
    if (raw.contains('afib') || raw.contains('atrial')) return 'Atrial Fib.';
    if (raw.contains('tachy')) return 'Tachycardia';
    if (raw.contains('brady')) return 'Bradycardia';
    if (raw.contains('pvc') || raw.contains('premature')) return 'PVC Detected';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  bool _isNormal(Map<String, dynamic> r) {
    final lbl = _rhythmLabel(r).toLowerCase();
    return lbl.contains('normal') || lbl.contains('sinus');
  }

  double _confidence(Map<String, dynamic> r) {
    final raw = r['confidence'] ?? r['score'] ?? r['probability'] ??
        r['prob'] ?? r['certainty'];
    if (raw == null) return 0;
    final v = double.tryParse(raw.toString()) ?? 0;
    return v > 1 ? v / 100 : v;
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: petrolDark,
        title: const Text(
          'Arrhythmia Check',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildActionButton(),
            const SizedBox(height: 20),
            if (_loading) _buildLoadingCard(),
            if (_error != null) _buildErrorCard(),
            if (_result != null) ..._buildResultCards(),
            if (!_loading && _error == null && _result == null) _buildIdleCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [petrolDark, petrol],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: petrolDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heart Rhythm Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'AI-powered arrhythmia detection using your PPG data.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _runCheck,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.radar_outlined, color: Colors.white),
        label: Text(
          _loading ? 'Analyzing...' : 'Run Arrhythmia Check',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _loading ? Colors.grey : Colors.red.shade600,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: _loading ? 0 : 4,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: petrolDark, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            'Fetching PPG data and running AI model...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.touch_app_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Press the button above to analyze\nyour latest heart rhythm data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!.replaceFirst('Exception: ', ''),
              style: TextStyle(color: Colors.red.shade800, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResultCards() {
    final r = _result!;
    final normal = _isNormal(r);
    final label = _rhythmLabel(r);
    final conf = _confidence(r);

    final statusColor =
        normal ? Colors.green.shade600 : Colors.red.shade600;
    final statusBg = normal ? Colors.green.shade50 : Colors.red.shade50;
    final statusBorder =
        normal ? Colors.green.shade200 : Colors.red.shade200;

    return [
      // ── Status card ──────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: statusBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                normal
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: statusColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    normal ? 'Normal Rhythm' : 'Abnormal Rhythm',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: statusColor.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // ── Confidence card ──────────────────────────────────────────────────
      if (conf > 0) ...[
        _buildMetricCard(
          icon: Icons.percent_rounded,
          iconColor: Colors.blue.shade600,
          title: 'Confidence',
          value: '${(conf * 100).toStringAsFixed(1)}%',
          subtitle: conf >= 0.85
              ? 'High confidence'
              : conf >= 0.6
                  ? 'Moderate confidence'
                  : 'Low confidence — consult a doctor',
          progress: conf,
          progressColor: conf >= 0.85
              ? Colors.blue.shade600
              : conf >= 0.6
                  ? Colors.orange
                  : Colors.red,
        ),
        const SizedBox(height: 14),
      ],

      // ── Detail card ──────────────────────────────────────────────────────
      _buildDetailCard(r),
      const SizedBox(height: 14),

      // ── Advice card ──────────────────────────────────────────────────────
      _buildAdviceCard(normal, label),
    ];
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> r) {
    const knownKeys = {
      'rhythm', 'label', 'prediction', 'class', 'result',
      'confidence', 'score', 'probability', 'prob', 'certainty',
    };
    final entries = r.entries.where((e) => !knownKeys.contains(e.key)).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: petrolDark, size: 20),
              SizedBox(width: 8),
              Text(
                'Analysis Details',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    e.key,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    e.value.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(bool normal, String label) {
    final icon =
        normal ? Icons.thumb_up_alt_outlined : Icons.medical_services_outlined;
    final color = normal ? Colors.green.shade700 : Colors.red.shade700;
    final title = normal ? 'All Clear!' : 'Consult a Doctor';
    final body = normal
        ? 'Your heart rhythm appears normal. Continue your healthy routine and stay active.'
        : 'An abnormal rhythm ($label) was detected. Please contact your cardiologist or healthcare provider as soon as possible.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    height: 1.5,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
