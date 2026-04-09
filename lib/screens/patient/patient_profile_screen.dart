import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../models/vital_sample.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';

class PatientProfileScreen extends StatelessWidget {
  final Patient patient;

  const PatientProfileScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final VitalSample? latest = app.getLatestVitals(patient.id);

        return Scaffold(
          backgroundColor: const Color(0xffF6F8FB),
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
            backgroundColor: PETROL_DARK,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      backgroundColor: PETROL.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: PETROL_DARK,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: PETROL_DARK,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Age: ${patient.age}',
                            style: const TextStyle(
                              color: Colors.black54,
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
                                    ? 'Device connected'
                                    : 'Device disconnected',
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
              const Text(
                'Latest Readings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PETROL_DARK,
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
                    title: 'Heart Rate',
                    value: latest?.hr.toString() ?? '--',
                    unit: 'bpm',
                    color: Colors.red,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.air_rounded,
                    title: 'SpO2',
                    value: latest?.spo2.toString() ?? '--',
                    unit: '%',
                    color: Colors.blue,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.monitor_heart_rounded,
                    title: 'Blood Pressure',
                    value: latest == null
                        ? '--'
                        : '${latest.sys}/${latest.dia}',
                    unit: 'mmHg',
                    color: Colors.purple,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.bloodtype_rounded,
                    title: 'Glucose',
                    value: latest == null
                        ? '--'
                        : latest.glucose.toInt().toString(),
                    unit: latest == null ? '' : 'mg/dL',
                    color: Colors.teal,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.thermostat_rounded,
                    title: 'Temperature',
                    value: latest == null
                        ? '--'
                        : latest.temperature.toStringAsFixed(1),
                    unit: '°C',
                    color: Colors.orange,
                  ),
                  _ProfileReadingCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'Alerts',
                    value: app
                        .getAlertsForPatient(patient.id)
                        .length
                        .toString(),
                    unit: '',
                    color: Colors.redAccent,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              unit.isEmpty ? value : '$value $unit',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}
