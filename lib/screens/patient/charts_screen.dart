import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../providers/app_state.dart';
import '../../models/vital_sample.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals Charts'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, app, child) {
          final list = app.vitals;

          if (list.isEmpty) {
            return const Center(child: Text('No vitals to display.'));
          }

          // ترتيب البيانات
          final sorted = [...list]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // تحويل البيانات لنقاط
          final hrSpots = _toSpots(sorted, (v) => v.hr.toDouble());
          final spo2Spots = _toSpots(sorted, (v) => v.spo2.toDouble());
          final tempSpots = _toSpots(sorted, (v) => v.temperature);
          final glucoseSpots = _toSpots(sorted, (v) => v.glucose);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Heart Rate Chart
                _UnifiedRiskChart(
                  title: "Heart Rate (bpm)",
                  points: hrSpots,
                  minY: 40, maxY: 180,
                  zones: [
                    _ChartZone(min: 60, max: 100, color: Colors.blue, label: "Normal"),
                    _ChartZone(min: 100, max: 120, color: Colors.amber, label: "High"),
                    _ChartZone(min: 120, max: 180, color: Colors.red, label: "Danger"),
                  ],
                  lineColor: Colors.blue.shade700,
                ),
                
                const SizedBox(height: 20),

                // 2. Oxygen Chart
                _UnifiedRiskChart(
                  title: "SpO₂ (%)",
                  points: spo2Spots,
                  minY: 80, maxY: 100,
                  zones: [
                    _ChartZone(min: 95, max: 100, color: Colors.blue, label: "Normal"),
                    _ChartZone(min: 90, max: 95, color: Colors.amber, label: "Low"),
                    _ChartZone(min: 80, max: 90, color: Colors.red, label: "Danger"),
                  ],
                  lineColor: Colors.teal,
                ),

                const SizedBox(height: 20),

                // 3. Glucose Chart
                _UnifiedRiskChart(
                  title: "Blood Glucose (mg/dL)",
                  points: glucoseSpots,
                  minY: 50, maxY: 400,
                  zones: [
                    _ChartZone(min: 70, max: 140, color: Colors.blue, label: "Normal"),
                    _ChartZone(min: 140, max: 180, color: Colors.amber, label: "Elevated"),
                    _ChartZone(min: 180, max: 400, color: Colors.red, label: "High"),
                  ],
                  lineColor: Colors.purple,
                ),

                const SizedBox(height: 20),

                // 4. Temperature Chart
                _UnifiedRiskChart(
                  title: "Temperature (°C)",
                  points: tempSpots,
                  minY: 35, maxY: 42,
                  zones: [
                    _ChartZone(min: 36.5, max: 37.5, color: Colors.blue, label: "Normal"),
                    _ChartZone(min: 37.5, max: 38.5, color: Colors.amber, label: "Fever"),
                    _ChartZone(min: 38.5, max: 42, color: Colors.red, label: "High Fever"),
                  ],
                  lineColor: Colors.orange,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<FlSpot> _toSpots(List<VitalSample> data, double Function(VitalSample) extractor) {
    return List.generate(data.length, (i) => FlSpot(i.toDouble(), extractor(data[i])));
  }
}

// ============================================================================
// 🔥🔥 الويدجت الموحدة لكل الشارتات (تصميم Oxygen) 🔥🔥
// ============================================================================

class _ChartZone {
  final double min;
  final double max;
  final Color color;
  final String label;
  _ChartZone({required this.min, required this.max, required this.color, required this.label});
}

class _UnifiedRiskChart extends StatelessWidget {
  final String title;
  final List<FlSpot> points;
  final double minY;
  final double maxY;
  final List<_ChartZone> zones;
  final Color lineColor;

  const _UnifiedRiskChart({
    required this.title,
    required this.points,
    required this.minY,
    required this.maxY,
    required this.zones,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxX = points.isEmpty ? 10.0 : (points.length - 1).toDouble();

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            // مفتاح الألوان (Chips)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: zones.map((z) => _legendChip(z.color, z.label)).toList(),
            ),
            
            const SizedBox(height: 20),

            // الرسم البياني
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  // 1. الخلفية الملونة
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: zones.map((z) {
                      return HorizontalRangeAnnotation(
                        y1: z.min, y2: z.max,
                        color: z.color.withOpacity(0.12),
                      );
                    }).toList(),
                  ),
                  // 2. الخطوط الأفقية الفاصلة
                  extraLinesData: ExtraLinesData(
                    horizontalLines: zones.map((z) {
                      return HorizontalLine(
                        y: z.max,
                        color: z.color.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    }).toList(),
                  ),
                  // 3. المحاور (Axes)
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5, // كل 5 قراءات رقم
                        getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: (maxY - minY) / 5,
                        getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                  // 4. الخط الرئيسي
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withOpacity(0.1), // تظليل خفيف تحت الخط
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

  Widget _legendChip(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}