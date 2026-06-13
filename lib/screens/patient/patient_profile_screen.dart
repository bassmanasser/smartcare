import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../models/vital_sample.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

class PatientProfileScreen extends StatelessWidget {
  final Patient patient;

  const PatientProfileScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final lang = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final bodyColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
        final subColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
        final VitalSample? latest = app.getLatestVitals(patient.id);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(lang.translate('profile')),
            centerTitle: true,
            backgroundColor: petrolDark,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: petrol.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: petrolDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: bodyColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${lang.translate('age')}: ${patient.age}',
                            style: TextStyle(
                              color: subColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                app.isDeviceConnected
                                    ? Icons.bluetooth_connected
                                    : Icons.bluetooth_disabled,
                                size: 18,
                                color: app.isDeviceConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                app.isDeviceConnected
                                    ? lang.translate('device_connected')
                                    : lang.translate('device_disconnected'),
                                style: TextStyle(
                                  color: app.isDeviceConnected
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                lang.translate('latest_readings'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ProfileReadingCard(
                    icon: Icons.favorite_rounded,
                    title: lang.translate('heart_rate'),
                    value: (latest == null || latest.hr == 0) ? '--' : latest.hr.toString(),
                    unit: 'bpm',
                    color: Colors.red,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.air_rounded,
                    title: lang.translate('spo2'),
                    value: (latest == null || latest.spo2 == 0) ? '--' : latest.spo2.toString(),
                    unit: '%',
                    color: Colors.blue,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.monitor_heart_rounded,
                    title: lang.translate('blood_pressure'),
                    value: (latest == null || (latest.sys == 0 && latest.dia == 0))
                        ? '--'
                        : '${latest.sys}/${latest.dia}',
                    unit: 'mmHg',
                    color: Colors.purple,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.bloodtype_rounded,
                    title: lang.translate('glucose'),
                    value: latest == null
                        ? '--'
                        : latest.glucose.toInt().toString(),
                    unit: latest == null ? '' : 'mg/dL',
                    color: Colors.teal,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.thermostat_rounded,
                    title: lang.translate('temperature'),
                    value: latest == null
                        ? '--'
                        : latest.temperature.toStringAsFixed(1),
                    unit: '°C',
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileReadingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color color;

  const _ProfileReadingCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              unit.isEmpty ? value : '$value $unit',
              style: TextStyle(
                color: bodyColor,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
