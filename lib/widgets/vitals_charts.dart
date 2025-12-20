import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/vital_sample.dart';
// ignore: unused_import
import '../utils/constants.dart';
import '../utils/localization.dart';

class VitalsCharts extends StatelessWidget {
  final List<VitalSample> samples;
  const VitalsCharts({super.key, required this.samples});

  List<FlSpot> _map(num Function(VitalSample) f) {
    final List<FlSpot> out = [];
    for (var i = 0; i < samples.length; i++) {
      out.add(FlSpot(i.toDouble(), f(samples[i]).toDouble()));
    }
    return out;
  }

  Color _getVitalColor(double value, double normalMin, double normalMax, double warnMin, double warnMax) {
    if (value >= normalMin && value <= normalMax) {
      return Colors.blue.shade700; // Normal
    } else if (value >= warnMin && value <= warnMax) {
      return Colors.amber.shade700; // Warning
    } else {
      return Colors.red.shade700; // Abnormal/Danger
    }
  }

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) return const Center(child: Text("No data."));
    final lastSample = samples.last;

    final hrColor = _getVitalColor(lastSample.hr.toDouble(), 60, 100, 50, 120);
    final spColor = _getVitalColor(lastSample.spo2.toDouble(), 95, 100, 92, 94);
    final tpColor = _getVitalColor(lastSample.temp, 36.5, 37.5, 37.6, 38.5);
    final glColor = _getVitalColor(lastSample.glucose.toDouble(), 70, 140, 141, 180);

    final hrSpots = _map((v) => v.hr);
    final spSpots = _map((v) => v.spo2);
    final tpSpots = _map((v) => v.temp);
    final glSpots = _map((v) => v.glucose);

    Widget lineChartWidget(String title, List<FlSpot> spots, double min, double max, Color color) => SizedBox(
      height: 140,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: min,
                    maxY: max,
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        dotData: const FlDotData(show: false),
                        color: color,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        lineChartWidget(L10n.get(context, 'heartRate', onChanged: (String? value) {  }), hrSpots, 40, 140, hrColor),
        const SizedBox(height: 8),
        lineChartWidget(L10n.get(context, 'spo2', onChanged: (String? value) {  }), spSpots, 85, 100, spColor),
        const SizedBox(height: 8),
        lineChartWidget(L10n.get(context, 'temp', onChanged: (String? value) {  }), tpSpots, 35, 40, tpColor),
        const SizedBox(height: 8),
        lineChartWidget(L10n.get(context, 'glucose', onChanged: (String? value) {  }), glSpots, 60, 200, glColor),
      ],
    );
  }
}