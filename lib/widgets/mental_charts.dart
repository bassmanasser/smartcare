import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_record.dart';
import '../utils/constants.dart';

class MentalCharts extends StatelessWidget {
  final List<MoodRecord> records;
  const MentalCharts({super.key, required this.records});
  
  Color? get PETROL_ACC => null;

  @override
  Widget build(BuildContext context) {
    final spotsMood = <FlSpot>[];
    final spotsSleep = <FlSpot>[];
    final barsStress = <BarChartGroupData>[];

    for (var i = 0; i < records.length; i++) {
      final item = records[i];
      spotsMood.add(FlSpot(i.toDouble(), item.mood.toDouble()));
      spotsSleep.add(FlSpot(i.toDouble(), item.sleep));
      barsStress.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (item.stress ?? 0).toDouble(),
            color: PETROL_ACC,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mood Trend (1-5)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              minY: 1,
              maxY: 5,
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spotsMood,
                  isCurved: true,
                  color: PETROL,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: PETROL.withOpacity(0.2)),
                )
              ],
            ))),
        const SizedBox(height: 24),
        const Text("Sleep Hours", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: 12,
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spotsSleep,
                  isCurved: true,
                  color: PETROL_ACC,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: PETROL_ACC.withOpacity(0.2)),
                )
              ],
            ))),
        const SizedBox(height: 24),
        const Text("Stress Level (0-10)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              barGroups: barsStress,
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true),
            ))),
      ],
    );
  }
}

/// Provide a fallback `sleep` getter for MoodRecord so the chart compilation succeeds.
extension on MoodRecord {
  double get sleep => 0.0;
}

extension on String {
  double toDouble() {
    return double.tryParse(this) ?? 0.0;
  }
}

extension on Color? {
  Color? withOpacity(double opacity) {
    // If the color is null, return a transparent color to avoid nulls
    return this?.withOpacity(opacity) ?? Colors.transparent;
  }
}