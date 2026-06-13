import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../providers/app_state.dart';
import '../../models/vital_sample.dart';
import '../../utils/localization.dart';

// ─── Time aggregation mode ───────────────────────────────────────────────────

enum _ChartMode { raw, hourly, daily }

// ─── Data models ─────────────────────────────────────────────────────────────

class _Pt {
  final String label;
  final double y;
  const _Pt(this.label, this.y);
}

class _BPPt {
  final String label;
  final double sys;
  final double dia;
  const _BPPt(this.label, this.sys, this.dia);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChartsScreen extends StatefulWidget {
  final String patientId;
  const ChartsScreen({super.key, required this.patientId});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchHistory(widget.patientId);
    });
  }

  // ── Mode detection ────────────────────────────────────────────────────────

  _ChartMode _detectMode(List<VitalSample> s) {
    if (s.length < 2) return _ChartMode.raw;
    final span = s.last.timestamp.difference(s.first.timestamp);
    if (span.inHours < 1) return _ChartMode.raw;
    if (span.inHours < 24) return _ChartMode.hourly;
    return _ChartMode.daily;
  }

  // ── Aggregation ───────────────────────────────────────────────────────────

  List<_Pt> _aggregate(
    List<VitalSample> sorted,
    double? Function(VitalSample) extractor,
    _ChartMode mode,
  ) {
    switch (mode) {
      case _ChartMode.raw:
        return sorted.where((s) => extractor(s) != null).map((s) {
          final t = s.timestamp;
          final lbl =
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          return _Pt(lbl, extractor(s)!);
        }).toList();

      case _ChartMode.hourly:
        final groups = <String, List<double>>{};
        final order = <String>[];
        for (final s in sorted) {
          final v = extractor(s);
          if (v == null) continue;
          final lbl =
              '${s.timestamp.hour.toString().padLeft(2, '0')}:00';
          if (!groups.containsKey(lbl)) {
            groups[lbl] = [];
            order.add(lbl);
          }
          groups[lbl]!.add(v);
        }
        return order.map((k) {
          final vals = groups[k]!;
          final avg = vals.reduce((a, b) => a + b) / vals.length;
          return _Pt(k, avg);
        }).toList();

      case _ChartMode.daily:
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        final groups = <String, List<double>>{};
        final order = <String>[];
        for (final s in sorted) {
          final v = extractor(s);
          if (v == null) continue;
          final lbl = '${s.timestamp.day} ${months[s.timestamp.month - 1]}';
          if (!groups.containsKey(lbl)) {
            groups[lbl] = [];
            order.add(lbl);
          }
          groups[lbl]!.add(v);
        }
        return order.map((k) {
          final vals = groups[k]!;
          final avg = vals.reduce((a, b) => a + b) / vals.length;
          return _Pt(k, avg);
        }).toList();
    }
  }

  List<_BPPt> _aggregateBP(List<VitalSample> sorted, _ChartMode mode) {
    switch (mode) {
      case _ChartMode.raw:
        return sorted
            .where((s) => s.sys > 0 || s.dia > 0)
            .map((s) {
          final t = s.timestamp;
          final lbl =
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          return _BPPt(lbl, s.sys.toDouble(), s.dia.toDouble());
        }).toList();

      case _ChartMode.hourly:
        final groups = <String, List<_BPPt>>{};
        final order = <String>[];
        for (final s in sorted) {
          final lbl =
              '${s.timestamp.hour.toString().padLeft(2, '0')}:00';
          if (!groups.containsKey(lbl)) {
            groups[lbl] = [];
            order.add(lbl);
          }
          groups[lbl]!.add(_BPPt(lbl, s.sys.toDouble(), s.dia.toDouble()));
        }
        return order.map((k) {
          final pts = groups[k]!;
          final avgSys = pts.map((p) => p.sys).reduce((a, b) => a + b) / pts.length;
          final avgDia = pts.map((p) => p.dia).reduce((a, b) => a + b) / pts.length;
          return _BPPt(k, avgSys, avgDia);
        }).toList();

      case _ChartMode.daily:
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        final groups = <String, List<_BPPt>>{};
        final order = <String>[];
        for (final s in sorted) {
          final lbl = '${s.timestamp.day} ${months[s.timestamp.month - 1]}';
          if (!groups.containsKey(lbl)) {
            groups[lbl] = [];
            order.add(lbl);
          }
          groups[lbl]!.add(_BPPt(lbl, s.sys.toDouble(), s.dia.toDouble()));
        }
        return order.map((k) {
          final pts = groups[k]!;
          final avgSys = pts.map((p) => p.sys).reduce((a, b) => a + b) / pts.length;
          final avgDia = pts.map((p) => p.dia).reduce((a, b) => a + b) / pts.length;
          return _BPPt(k, avgSys, avgDia);
        }).toList();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('charts')),
        backgroundColor: petrolDark,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, app, _) {
          final list = app.vitals;

          if (list.isEmpty) {
            return Center(child: Text(lang.translate('no_data')));
          }

          final sorted = [...list]
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          final mode = _detectMode(sorted);

          final modeLabel = mode == _ChartMode.raw
              ? lang.translate('chart_mode_live')
              : mode == _ChartMode.hourly
                  ? lang.translate('chart_mode_hourly')
                  : lang.translate('chart_mode_daily');

          // Extractors (return null to skip 0/invalid readings)
          double? hrEx(VitalSample v) => v.hr > 0 ? v.hr.toDouble() : null;
          double? spEx(VitalSample v) => v.spo2 > 0 ? v.spo2.toDouble() : null;
          double? glEx(VitalSample v) => v.glucose > 0 ? v.glucose : null;
          double? tmEx(VitalSample v) =>
              v.temperature > 30 ? v.temperature : null;

          final hrData = _aggregate(sorted, hrEx, mode);
          final spData = _aggregate(sorted, spEx, mode);
          final glData = _aggregate(sorted, glEx, mode);
          final tmData = _aggregate(sorted, tmEx, mode);
          final bpData = _aggregateBP(sorted, mode);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: petrol.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: petrol.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timeline_rounded,
                          size: 16, color: petrolDark),
                      const SizedBox(width: 8),
                      Text(modeLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: petrolDark,
                              fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        '• ${sorted.length} ${lang.translate('readings')}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Heart Rate
                _VitalChart(
                  title: '${lang.translate('heart_rate')} (bpm)',
                  data: hrData,
                  minY: 30, maxY: 180,
                  zones: [
                    _Zone(60, 100, Colors.green, lang.translate('normal')),
                    _Zone(100, 120, Colors.amber, lang.translate('high')),
                    _Zone(120, 180, Colors.red, lang.translate('danger')),
                  ],
                  lineColor: Colors.pinkAccent,
                ),
                const SizedBox(height: 16),

                // 2. SpO2
                _VitalChart(
                  title: '${lang.translate('spo2')} (%)',
                  data: spData,
                  minY: 80, maxY: 100,
                  zones: [
                    _Zone(95, 100, Colors.green, lang.translate('normal')),
                    _Zone(90, 95, Colors.amber, lang.translate('low')),
                    _Zone(80, 90, Colors.red, lang.translate('danger')),
                  ],
                  lineColor: Colors.blue,
                ),
                const SizedBox(height: 16),

                // 3. Blood Pressure (two lines)
                _BPChart(
                  title: '${lang.translate('blood_pressure')} (mmHg)',
                  data: bpData,
                  sysLabel: lang.translate('systolic'),
                  diaLabel: lang.translate('diastolic'),
                ),
                const SizedBox(height: 16),

                // 4. Glucose
                _VitalChart(
                  title: '${lang.translate('glucose')} (mg/dL)',
                  data: glData,
                  minY: 40, maxY: 400,
                  zones: [
                    _Zone(70, 140, Colors.green, lang.translate('normal')),
                    _Zone(140, 180, Colors.amber, lang.translate('elevated')),
                    _Zone(180, 400, Colors.red, lang.translate('high')),
                  ],
                  lineColor: Colors.purple,
                ),
                const SizedBox(height: 16),

                // 5. Temperature
                _VitalChart(
                  title: '${lang.translate('temperature')} (°C)',
                  data: tmData,
                  minY: 35, maxY: 42,
                  zones: [
                    _Zone(36.5, 37.5, Colors.green, lang.translate('normal')),
                    _Zone(37.5, 38.5, Colors.amber, lang.translate('fever')),
                    _Zone(38.5, 42, Colors.red, lang.translate('high_fever')),
                  ],
                  lineColor: Colors.orange,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Zone model ───────────────────────────────────────────────────────────────

class _Zone {
  final double min;
  final double max;
  final Color color;
  final String label;
  const _Zone(this.min, this.max, this.color, this.label);
}

// ─── Generic vital chart ──────────────────────────────────────────────────────

class _VitalChart extends StatelessWidget {
  final String title;
  final List<_Pt> data;
  final double minY;
  final double maxY;
  final List<_Zone> zones;
  final Color lineColor;

  const _VitalChart({
    required this.title,
    required this.data,
    required this.minY,
    required this.maxY,
    required this.zones,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots =
        List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].y));
    final maxX = (data.length - 1).toDouble();
    final xInterval = (data.length / 5).ceil().clamp(1, 9999).toDouble();
    final yInterval = (maxY - minY) / 4;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    zones.map((z) => _chip(z.color, z.label)).toList(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: zones
                        .map((z) => HorizontalRangeAnnotation(
                              y1: z.min,
                              y2: z.max,
                              color: z.color.withValues(alpha: 0.1),
                            ))
                        .toList(),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: zones
                        .map((z) => HorizontalLine(
                              y: z.max,
                              color: z.color.withValues(alpha: 0.45),
                              strokeWidth: 1,
                              dashArray: [5, 4],
                            ))
                        .toList(),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: yInterval,
                        getTitlesWidget: (val, _) => Text(
                          val.toStringAsFixed(
                              val == val.roundToDouble() ? 0 : 1),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 26,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              data[idx].label,
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.18),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.25)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: data.length <= 25,
                        getDotPainter: (_, _, _, _) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: lineColor,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            lineColor.withValues(alpha: 0.28),
                            lineColor.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─── Blood Pressure chart (two lines: sys + dia) ──────────────────────────────

class _BPChart extends StatelessWidget {
  final String title;
  final List<_BPPt> data;
  final String sysLabel;
  final String diaLabel;

  const _BPChart({
    required this.title,
    required this.data,
    required this.sysLabel,
    required this.diaLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sysSpots =
        List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].sys));
    final diaSpots =
        List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].dia));
    final maxX = (data.length - 1).toDouble();
    final xInterval = (data.length / 5).ceil().clamp(1, 9999).toDouble();

    final sysColor = Colors.red.shade700;
    final diaColor = Colors.blue.shade600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _chip(sysColor, '$sysLabel (↑120)'),
                  _chip(diaColor, '$diaLabel (↑80)'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: 40,
                  maxY: 200,
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                          y1: 90, y2: 120,
                          color: sysColor.withValues(alpha: 0.06)),
                      HorizontalRangeAnnotation(
                          y1: 60, y2: 80,
                          color: diaColor.withValues(alpha: 0.06)),
                    ],
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                          y: 120,
                          color: sysColor.withValues(alpha: 0.4),
                          strokeWidth: 1,
                          dashArray: [5, 4]),
                      HorizontalLine(
                          y: 80,
                          color: diaColor.withValues(alpha: 0.4),
                          strokeWidth: 1,
                          dashArray: [5, 4]),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 40,
                        getTitlesWidget: (val, _) => Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 26,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(data[idx].label,
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.18),
                        strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.25)),
                  ),
                  lineBarsData: [
                    // Systolic
                    LineChartBarData(
                      spots: sysSpots,
                      isCurved: true,
                      color: sysColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: data.length <= 25,
                        getDotPainter: (_, _, _, _) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: sysColor,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            sysColor.withValues(alpha: 0.15),
                            sysColor.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Diastolic
                    LineChartBarData(
                      spots: diaSpots,
                      isCurved: true,
                      color: diaColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: data.length <= 25,
                        getDotPainter: (_, _, _, _) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: diaColor,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
