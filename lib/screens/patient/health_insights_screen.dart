import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/medical_report_service.dart';

class HealthInsightsScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const HealthInsightsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final repo = PatientDataRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: PETROL_DARK,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: repo.latestVitalsStream(patientId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final v = snap.data;
          if (v == null) {
            return const Center(child: Text('No vitals yet.'));
          }

          // expected fields (you can change later):
          final hr = toIntSafe(v['hr']) ?? toIntSafe(v['heartRate']);
          final spo2 = toIntSafe(v['spo2']);
          final temp = toDoubleSafe(v['temperature']) ?? toDoubleSafe(v['tempC']);
          final sys = toIntSafe(v['sys']);
          final dia = toIntSafe(v['dia']);

          // You said: Predicted Glucose AI
          final glucoseAi = toDoubleSafe(v['Predicted Glucose AI']) ??
              toDoubleSafe(v['predicted_glucose_ai']) ??
              toDoubleSafe(v['glucose_ai']);

          // optional: real glucose
          final glucose = toDoubleSafe(v['glucose']) ?? glucoseAi;

          final fallFlag = (v['fallFlag'] == true) || (v['fall_detected'] == true);

          final insights = <_InsightItem>[];

          if (glucose != null) {
            final sev = _glucoseSeverity(glucose);
            insights.add(_InsightItem(
              title: 'Glucose (AI)',
              value: '${glucose.toStringAsFixed(0)} mg/dL',
              severity: sev,
              icon: Icons.bloodtype,
              details: AdviceBuilder.glucoseAdvice(glucose),
            ));
          } else {
            insights.add(_InsightItem(
              title: 'Glucose (AI)',
              value: '--',
              severity: _Severity.info,
              icon: Icons.bloodtype,
              details: const ['No glucose value received yet.'],
            ));
          }

          if (hr != null) {
            final sev = (HealthRules.hrLow(hr) || HealthRules.hrHigh(hr))
                ? _Severity.warning
                : _Severity.good;
            insights.add(_InsightItem(
              title: 'Heart Rate',
              value: '$hr bpm',
              severity: sev,
              icon: Icons.favorite,
              details: [
                if (HealthRules.hrLow(hr)) 'HR is low. If dizziness: consult doctor.',
                if (HealthRules.hrHigh(hr)) 'HR is high. Rest + recheck. If chest pain: SOS.',
                if (!HealthRules.hrLow(hr) && !HealthRules.hrHigh(hr)) 'HR is within normal range.',
              ],
            ));
          }

          if (spo2 != null) {
            final sev = HealthRules.spo2Danger(spo2)
                ? _Severity.danger
                : (HealthRules.spo2Warn(spo2) ? _Severity.warning : _Severity.good);
            insights.add(_InsightItem(
              title: 'SpO₂',
              value: '$spo2 %',
              severity: sev,
              icon: Icons.monitor_heart,
              details: [
                if (HealthRules.spo2Danger(spo2)) 'Critical oxygen level. Seek medical help now.',
                if (HealthRules.spo2Warn(spo2)) 'Low oxygen. Sit upright and recheck.',
                if (!HealthRules.spo2Danger(spo2) && !HealthRules.spo2Warn(spo2))
                  'Oxygen level looks good.',
              ],
            ));
          }

          if (temp != null) {
            final sev = (HealthRules.tempFever(temp) || HealthRules.tempLow(temp))
                ? _Severity.warning
                : _Severity.good;
            insights.add(_InsightItem(
              title: 'Temperature',
              value: '${temp.toStringAsFixed(1)} °C',
              severity: sev,
              icon: Icons.thermostat,
              details: [
                if (HealthRules.tempFever(temp)) 'Fever suspected. Hydrate + rest, consult doctor.',
                if (HealthRules.tempLow(temp)) 'Low temperature. Keep warm and recheck.',
                if (!HealthRules.tempFever(temp) && !HealthRules.tempLow(temp))
                  'Temperature is within normal range.',
              ],
            ));
          }

          if (sys != null && dia != null) {
            insights.add(_InsightItem(
              title: 'Blood Pressure',
              value: '$sys / $dia mmHg',
              severity: _Severity.info,
              icon: Icons.speed,
              details: const ['BP is shown for reference (set medical rules if needed).'],
            ));
          }

          if (fallFlag) {
            insights.insert(
              0,
              _InsightItem(
                title: 'Fall Detection',
                value: '⚠ Possible Fall',
                severity: _Severity.danger,
                icon: Icons.warning_amber_rounded,
                details: AdviceBuilder.fallAdvice(),
              ),
            );
          } else {
            insights.insert(
              0,
              _InsightItem(
                title: 'Fall Detection',
                value: 'No fall detected',
                severity: _Severity.good,
                icon: Icons.shield,
                details: const ['No fall event in the latest reading.'],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hello, $patientName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Insights based on latest sensor readings.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              ...insights.map((x) => _InsightCard(item: x)),
              const SizedBox(height: 14),
              _TipsCard(glucoseAi: glucoseAi),
            ],
          );
        },
      ),
    );
  }

  static _Severity _glucoseSeverity(double g) {
    if (HealthRules.glucoseLow(g)) return _Severity.danger;
    if (HealthRules.glucoseHigh(g)) return _Severity.danger;
    if (HealthRules.glucoseMedium(g)) return _Severity.warning;
    return _Severity.good;
  }
}

enum _Severity { good, info, warning, danger }

class _InsightItem {
  final String title;
  final String value;
  final _Severity severity;
  final IconData icon;
  final List<String> details;

  _InsightItem({
    required this.title,
    required this.value,
    required this.severity,
    required this.icon,
    required this.details,
  });
}

class _InsightCard extends StatelessWidget {
  final _InsightItem item;
  const _InsightCard({required this.item});

  Color _barColor() {
    switch (item.severity) {
      case _Severity.good:
        return Colors.green;
      case _Severity.info:
        return PETROL;
      case _Severity.warning:
        return Colors.orange;
      case _Severity.danger:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bar = _barColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: bar.withOpacity(0.12),
                  child: Icon(item.icon, color: bar),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bar.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.value,
                    style: TextStyle(color: bar, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 4, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 10),
            ...item.details.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: Colors.grey.shade700)),
                    Expanded(child: Text(t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final double? glucoseAi;
  const _TipsCard({required this.glucoseAi});

  @override
  Widget build(BuildContext context) {
    final tips = <String>[
      'Keep device connected for real-time updates.',
      'If symptoms appear, don’t wait for the app—use SOS.',
      'Hydration helps in high glucose conditions.',
      'For low glucose: use fast sugar and recheck after 15 minutes.',
    ];

    if (glucoseAi != null && glucoseAi! >= 180) {
      tips.insert(0, 'Tip: Your glucose is high → drink water now and avoid sugar.');
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Tips', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $t'),
                )),
          ],
        ),
      ),
    );
  }
}
