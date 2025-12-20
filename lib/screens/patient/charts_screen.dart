import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../models/vital_sample.dart';

enum GlucoseLevel { normal, medium, danger }

GlucoseLevel _glucoseLevel(double g) {
  if (g <= 140) return GlucoseLevel.normal;
  if (g <= 180) return GlucoseLevel.medium;
  return GlucoseLevel.danger;
}

Color _levelColor(GlucoseLevel l) {
  switch (l) {
    case GlucoseLevel.normal:
      return Colors.blue;
    case GlucoseLevel.medium:
      return Colors.amber;
    case GlucoseLevel.danger:
      return Colors.redAccent;
  }
}

class ChartsScreen extends StatelessWidget {
  final String patientId;
  const ChartsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final vitals = app.getVitalsForPatient(patientId);
    final sorted = [...vitals]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals Charts'),
        backgroundColor: PETROL_DARK,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: sorted.isEmpty
            ? const Center(child: Text('No vitals to display.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Heart Rate (bpm)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 210,
                    child: _SimpleLineChart(
                      points: _extractSeries(sorted, (v) => v.hr.toDouble()),
                      lineColor: PETROL,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Blood Glucose (mg/dL)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 240,
                    child: GlucoseRiskChart(
                      points: _extractSeries(sorted, (v) => (v.glucose as num?)?.toDouble()),
                      normalMax: 140,
                      mediumMax: 180,
                      minY: 50,
                      maxY: 300,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Temperature (°C)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 210,
                    child: _SimpleLineChart(
                      points: _extractSeries(sorted, (v) => (v.temperature as num?)?.toDouble()),
                      lineColor: Colors.orange,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

List<FlSpot> _extractSeries(
  List<VitalSample> vitals,
  double? Function(VitalSample) selector,
) {
  final filtered = <double>[];
  for (final v in vitals) {
    final val = selector(v);
    if (val != null) filtered.add(val);
  }
  final data = filtered.take(50).toList();
  final spots = <FlSpot>[];
  for (var i = 0; i < data.length; i++) {
    spots.add(FlSpot(i.toDouble(), data[i]));
  }
  return spots;
}

class _SimpleLineChart extends StatelessWidget {
  final List<FlSpot> points;
  final Color lineColor;

  const _SimpleLineChart({
    required this.points,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data to display'));

    double minY = points.first.y, maxY = points.first.y;
    for (final p in points) {
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    minY -= 5;
    maxY += 5;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            color: lineColor,
          ),
        ],
      ),
    );
  }
}

// =================== Glucose Risk Chart ===================

class GlucoseRiskChart extends StatelessWidget {
  final List<FlSpot> points;

  final double normalMax; // 140
  final double mediumMax; // 180

  final double minY;
  final double maxY;

  const GlucoseRiskChart({
    super.key,
    required this.points,
    this.normalMax = 140,
    this.mediumMax = 180,
    this.minY = 50,
    this.maxY = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data to display'));

    final lastY = points.last.y;
    final level = _glucoseLevel(lastY);
    final lineColor = _levelColor(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _legendChip(color: Colors.blue, text: "Normal (≤ $normalMax)"),
            _legendChip(color: Colors.amber, text: "Medium ($normalMax–$mediumMax)"),
            _legendChip(color: Colors.redAccent, text: "Danger (> $mediumMax)"),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: points.length.toDouble() - 1,
              minY: minY,
              maxY: maxY,

              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: minY,
                    y2: normalMax,
                    color: Colors.blue.withOpacity(0.10),
                  ),
                  HorizontalRangeAnnotation(
                    y1: normalMax,
                    y2: mediumMax,
                    color: Colors.amber.withOpacity(0.12),
                  ),
                  HorizontalRangeAnnotation(
                    y1: mediumMax,
                    y2: maxY,
                    color: Colors.redAccent.withOpacity(0.10),
                  ),
                ],
              ),

              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: normalMax,
                  color: Colors.blue.withOpacity(0.7),
                  strokeWidth: 1.5,
                  dashArray: [6, 6],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    labelResolver: (_) => "Normal max $normalMax",
                  ),
                ),
                HorizontalLine(
                  y: mediumMax,
                  color: Colors.redAccent.withOpacity(0.7),
                  strokeWidth: 1.5,
                  dashArray: [6, 6],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    labelResolver: (_) => "Danger starts $mediumMax",
                  ),
                ),
              ]),

              gridData: FlGridData(show: true, drawVerticalLine: false),

              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),

              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade400),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: true,
                  barWidth: 3,
                  color: lineColor,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) => spot == points.last,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withOpacity(0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendChip({required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
