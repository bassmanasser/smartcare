import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/vital_sample.dart';
import '../utils/localization.dart';

class VitalsCharts extends StatelessWidget {
  final List<VitalSample> samples;
  const VitalsCharts({super.key, required this.samples});

  List<FlSpot> _mapDouble(List<VitalSample> s, double? Function(VitalSample) f) {
    final out = <FlSpot>[];
    for (var i = 0; i < s.length; i++) {
      final y = f(s[i]);
      if (y == null) continue;
      out.add(FlSpot(i.toDouble(), y));
    }
    return out;
  }

  Widget _legendChip(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _zonedChart({
    required String title,
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
    required double normalMax,
    required double warnMax,
    required String normalText,
    required String warnText,
    required String dangerText,
    required Color lineColor,
    // Add logic to handle areas below/above normal if needed
    bool inverseDanger = false, // If true, danger is below normal (like SpO2)
  }) {
    final normalColor = Colors.green;
    final warnColor = Colors.amber;
    final dangerColor = Colors.red;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: lineColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _legendChip(normalColor, normalText),
                _legendChip(warnColor, warnText),
                _legendChip(dangerColor, dangerText),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: 0,
                  maxX: (spots.isEmpty ? 1 : spots.last.x),
                  titlesData: const FlTitlesData(show: false), // إخفاء الأرقام لتبسيط الشكل
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 5,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  
                  // 🔥 الخلفية الملونة (المناطق)
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: inverseDanger 
                    ? [ // لو الخطر تحت (زي الأكسجين)
                        HorizontalRangeAnnotation(y1: minY, y2: warnMax, color: dangerColor.withOpacity(0.1)),
                        HorizontalRangeAnnotation(y1: warnMax, y2: normalMax, color: warnColor.withOpacity(0.1)),
                        HorizontalRangeAnnotation(y1: normalMax, y2: maxY, color: normalColor.withOpacity(0.1)),
                      ]
                    : [ // لو الخطر فوق (زي الضغط والحرارة)
                        HorizontalRangeAnnotation(y1: minY, y2: normalMax, color: normalColor.withOpacity(0.1)),
                        HorizontalRangeAnnotation(y1: normalMax, y2: warnMax, color: warnColor.withOpacity(0.1)),
                        HorizontalRangeAnnotation(y1: warnMax, y2: maxY, color: dangerColor.withOpacity(0.1)),
                      ],
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true, // 🌊 خط منحني ناعم
                      color: lineColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      // 🔥 التدرج اللوني تحت الخط (Gradient)
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            lineColor.withOpacity(0.4),
                            lineColor.withOpacity(0.0),
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

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) return const Center(child: Text("No data yet."));

    final s = [...samples]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // تحويل البيانات لنقاط
    final hrSpots = _mapDouble(s, (v) => v.hr.toDouble());
    final spSpots = _mapDouble(s, (v) => v.spo2.toDouble());
    final glSpots = _mapDouble(s, (v) => v.glucoseMgdl?.toDouble());
    final tpSpots = _mapDouble(s, (v) => v.tempC);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. Heart Rate
          _zonedChart(
            title: "${L10n.get(context, 'heartRate', onChanged: (String? value) { })} (bpm)",
            spots: hrSpots,
            minY: 30, maxY: 180,
            normalMax: 100, warnMax: 120, // فوق 120 خطر
            normalText: "60-100", warnText: "100-120", dangerText: ">120",
            lineColor: const Color(0xFFE91E63), // Pink/Red
          ),
          const SizedBox(height: 16),

          // 2. SpO2 (Oxygen) - Danger is LOW
          _zonedChart(
            title: "${L10n.get(context, 'spo2', onChanged: (String? value) { })} (%)",
            spots: spSpots,
            minY: 80, maxY: 100,
            normalMax: 95, warnMax: 90, // تحت 90 خطر
            normalText: "≥95", warnText: "90-94", dangerText: "<90",
            lineColor: Colors.blue,
            inverseDanger: true, // لأن الرقم القليل هو الخطر
          ),
          const SizedBox(height: 16),

          // 3. Glucose
          _zonedChart(
            title: "${L10n.get(context, 'glucose', onChanged: (String? value) { })} (mg/dL)",
            spots: glSpots,
            minY: 40, maxY: 400,
            normalMax: 140, warnMax: 180,
            normalText: "70-140", warnText: "140-180", dangerText: ">180",
            lineColor: Colors.teal,
          ),
          const SizedBox(height: 16),

          // 4. Temperature
          _zonedChart(
            title: "${L10n.get(context, 'temp', onChanged: (String? value) { })} (°C)",
            spots: tpSpots,
            minY: 35, maxY: 42,
            normalMax: 37.5, warnMax: 38.5,
            normalText: "36.5-37.5", warnText: "37.5-38.5", dangerText: ">38.5",
            lineColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}

// Helper Mixin if not exists in utils (just to be safe)
mixin L10n {
  static String get(BuildContext context, String key, {required Function(String?) onChanged}) {
    // Basic fallback if localization logic is complex in your project
    if(key == 'heartRate') return 'Heart Rate';
    if(key == 'spo2') return 'Oxygen Saturation';
    if(key == 'glucose') return 'Blood Glucose';
    if(key == 'temp') return 'Temperature';
    return key;
  }
}