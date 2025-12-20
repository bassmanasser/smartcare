import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/medical_report_service.dart';

class EmergencyTimelineScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const EmergencyTimelineScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final repo = PatientDataRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Timeline'),
        backgroundColor: PETROL_DARK,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.alertsStream(patientId, limit: 120),
        builder: (context, alertsSnap) {
          if (alertsSnap.hasError) {
            return Center(child: Text('Error: ${alertsSnap.error}'));
          }
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.vitalsStream(patientId, limit: 120),
            builder: (context, vitalsSnap) {
              if (!alertsSnap.hasData || !vitalsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final alerts = alertsSnap.data!;
              final vitals = vitalsSnap.data!;

              final items = <_TimelineItem>[];

              // Alerts → timeline items
              for (final a in alerts) {
                final ts = tsToDate(a['timestamp']) ?? tsToDate(a['createdAt']);
                if (ts == null) continue;

                items.add(_TimelineItem(
                  time: ts,
                  type: _TimelineType.alert,
                  title: strSafe(a['message'], fallback: 'Alert'),
                  severity: strSafe(a['severity'], fallback: 'medium'),
                  extra: a,
                ));
              }

              // Fall events from vitals
              for (final v in vitals) {
                final ts = tsToDate(v['timestamp']) ?? tsToDate(v['createdAt']);
                if (ts == null) continue;

                final fall = (v['fallFlag'] == true) || (v['fall_detected'] == true);
                if (!fall) continue;

                items.add(_TimelineItem(
                  time: ts,
                  type: _TimelineType.fall,
                  title: 'Fall Detected',
                  severity: 'high',
                  extra: v,
                ));
              }

              items.sort((a, b) => b.time.compareTo(a.time));

              if (items.isEmpty) {
                return const Center(child: Text('No emergency events yet.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, i) => _TimelineCard(item: items[i]),
              );
            },
          );
        },
      ),
    );
  }
}

enum _TimelineType { alert, fall }

class _TimelineItem {
  final DateTime time;
  final _TimelineType type;
  final String title;
  final String severity;
  final Map<String, dynamic> extra;

  _TimelineItem({
    required this.time,
    required this.type,
    required this.title,
    required this.severity,
    required this.extra,
  });
}

class _TimelineCard extends StatelessWidget {
  final _TimelineItem item;
  const _TimelineCard({required this.item});

  Color _sevColor() {
    final s = item.severity.toLowerCase();
    if (s == 'high' || s == 'danger') return Colors.redAccent;
    if (s == 'medium' || s == 'warn') return Colors.orange;
    return PETROL;
  }

  IconData _icon() {
    if (item.type == _TimelineType.fall) return Icons.warning_amber_rounded;
    return Icons.notification_important;
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm  $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final c = _sevColor();

    final subtitleLines = <String>[];
    if (item.type == _TimelineType.alert) {
      subtitleLines.add('Alert severity: ${item.severity.toUpperCase()}');
    } else {
      subtitleLines.add('Possible fall detected by sensor.');
      subtitleLines.addAll(AdviceBuilder.fallAdvice());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: c.withOpacity(0.12),
              child: Icon(_icon(), color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Text(
                        _formatDate(item.time),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
                  ),
                  const SizedBox(height: 10),
                  ...subtitleLines.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $t'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
