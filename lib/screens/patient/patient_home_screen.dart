import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../models/alert_item.dart';
import '../../models/vital_sample.dart';
import '../../models/mood_record.dart';
import '../../models/medication.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';

import '../../services/vitals_service.dart';

import 'ai_bot_screen.dart';
import 'add_medication_screen.dart';
import '../chat/conversations_screen.dart';

import 'charts_screen.dart'; // ✅ هنضيفها كملف منفصل تحت

class PatientHomeScreen extends StatefulWidget {
  final Patient patient;
  const PatientHomeScreen({super.key, required this.patient});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _PatientHomeTab(patient: widget.patient),
      _PatientServicesTab(patient: widget.patient),
      _PatientSettingsTab(
        patient: widget.patient,
        onLogout: () async {
          Navigator.pop(context);
        },
      ),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: PETROL,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ---------------- HOME TAB ----------------

class _PatientHomeTab extends StatelessWidget {
  final Patient patient;
  const _PatientHomeTab({required this.patient});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _glucoseAdvice(double g) {
    // mg/dL thresholds (تقدري تعدليهم)
    if (g < 70) {
      return "Low glucose: eat something sweet (juice / dates) and re-check.";
    }
    if (g <= 140) {
      return "Glucose is normal. Keep hydration and balanced meals.";
    }
    if (g <= 180) {
      return "Glucose is a bit high: drink water, walk 10–15 min, avoid sugar now.";
    }
    return "High glucose: drink water, avoid carbs/sweets, consider contacting doctor if persistent.";
  }

  Color _glucoseColor(double g) {
    if (g < 70) return Colors.deepPurple;
    if (g <= 140) return Colors.blue;
    if (g <= 180) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final vitalsService = VitalsService();

    // alerts/vitals history demo من AppState (ممكن ننقلهم Firestore بعدين)
    final app = Provider.of<AppState>(context);
    final alerts = app.getAlertsForPatient(patient.id);
    final recentAlerts = [...alerts]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return SafeArea(
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: PETROL_DARK,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMARTCARE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_greeting()}, ${patient.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: PETROL.withOpacity(0.1),
                        child: Text(
                          patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            fontSize: 26,
                            color: PETROL_DARK,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.circle, color: Colors.green, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Active',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${patient.age} yrs • ${patient.gender}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BODY
          Expanded(
            child: StreamBuilder(
              stream: vitalsService.latestVitalsStream(patient.id),
              builder: (context, snap) {
                final v = snap.data; // object فيه hr/spo2/glucose/temp/fallFlag

                final glucoseVal = (v != null) ? (v.glucose as num).toDouble() : null;
                final tempVal = (v != null) ? (v.temperature as num).toDouble() : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Fall detection banner
                      if (v != null && v.fallFlag == true) ...[
                        _BannerCard(
                          color: Colors.redAccent,
                          icon: Icons.warning_amber_rounded,
                          title: "Fall Detected!",
                          body: "A fall was detected. Please check the patient immediately.",
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ✅ Glucose advice banner
                      if (glucoseVal != null) ...[
                        _BannerCard(
                          color: _glucoseColor(glucoseVal),
                          icon: Icons.bloodtype,
                          title: "Glucose Advice",
                          body: _glucoseAdvice(glucoseVal),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // vitals cards
                      Row(
                        children: [
                          Expanded(
                            child: _HomeVitalCard(
                              title: 'Heart Rate',
                              value: v != null ? '${v.hr}' : '--',
                              unit: 'bpm',
                              color: Colors.redAccent,
                              icon: Icons.favorite,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HomeVitalCard(
                              title: 'SpO₂',
                              value: v != null ? '${v.spo2}' : '--',
                              unit: '%',
                              color: Colors.blueAccent,
                              icon: Icons.bloodtype,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _HomeVitalCard(
                              title: 'Glucose',
                              value: glucoseVal != null ? glucoseVal.toStringAsFixed(0) : '--',
                              unit: 'mg/dL',
                              color: Colors.teal,
                              icon: Icons.bloodtype_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HomeVitalCard(
                              title: 'Temperature',
                              value: tempVal != null ? tempVal.toStringAsFixed(1) : '--',
                              unit: '°C',
                              color: Colors.orange,
                              icon: Icons.thermostat,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SOS
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SOS triggered (demo).')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          label: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Latest Alert',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (recentAlerts.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No critical alerts.'),
                          ),
                        )
                      else
                        _AlertTile(alert: recentAlerts.first),

                      const SizedBox(height: 24),

                      Text(
                        'Last Readings (demo)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Builder(
                        builder: (_) {
                          final vitalsDemo = app.getVitalsForPatient(patient.id);
                          final sorted = [...vitalsDemo]
                            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                          if (sorted.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No vitals recorded yet.'),
                              ),
                            );
                          }
                          return Column(
                            children: sorted.take(5).map((x) => _VitalListTile(v: x)).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _BannerCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
          color: color.withOpacity(0.10),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(color: Colors.grey.shade900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeVitalCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _HomeVitalCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- SERVICES TAB ----------------

class _PatientServicesTab extends StatelessWidget {
  final Patient patient;
  const _PatientServicesTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem(
        title: 'Medications',
        icon: Icons.medication,
        color: const Color(0xFF3B82F6),
        builder: (_) => MedicationsScreen(patientId: patient.id),
      ),
      _ServiceItem(
        title: 'Charts',
        icon: Icons.show_chart,
        color: Colors.green,
        builder: (_) => ChartsScreen(patientId: patient.id),
      ),
      _ServiceItem(
        title: 'Mood',
        icon: Icons.emoji_emotions,
        color: Colors.orange,
        builder: (_) => MoodScreen(patientId: patient.id),
      ),
      _ServiceItem(
        title: 'Alerts History',
        icon: Icons.warning_amber_rounded,
        color: Colors.redAccent,
        builder: (_) => AlertsHistoryScreen(patientId: patient.id),
      ),
      _ServiceItem(
        title: 'AI Bot',
        icon: Icons.smart_toy,
        color: Colors.purple,
        builder: (_) => AiBotScreen(patient: patient),
      ),
      _ServiceItem(
        title: 'Messages',
        icon: Icons.chat,
        color: Colors.teal,
        builder: (_) => ConversationsScreen(
          currentUserId: patient.id,
          currentRole: 'patient',
        ),
      ),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Services',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final s = services[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: s.builder)),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: s.color.withOpacity(0.1),
                            child: Icon(s.icon, color: s.color),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  _ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

// ---------------- SETTINGS TAB ----------------

class _PatientSettingsTab extends StatelessWidget {
  final Patient patient;
  final Future<void> Function() onLogout;

  const _PatientSettingsTab({
    required this.patient,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: PETROL,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(patient.name),
              subtitle: Text(
                patient.email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onLogout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- MEDICATIONS SCREEN ----------------

class MedicationsScreen extends StatelessWidget {
  final String patientId;
  const MedicationsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final meds = app.getMedicationsForPatient(patientId)..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: PETROL_DARK,
      ),
      body: meds.isEmpty
          ? const Center(child: Text('No active medications.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meds.length,
              itemBuilder: (context, index) => _MedicationTile(med: meds[index]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PETROL,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddMedicationScreen(patientId: patientId)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------- MOOD SCREEN (demo from AppState) ----------------

class MoodScreen extends StatelessWidget {
  final String patientId;
  const MoodScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final moods = app.getMoodForPatient(patientId)..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
        backgroundColor: PETROL_DARK,
      ),
      body: moods.isEmpty
          ? const Center(child: Text('No mood records.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: moods.length,
              itemBuilder: (context, index) => _MoodTile(mood: moods[index]),
            ),
    );
  }
}

// ---------------- ALERTS HISTORY (demo from AppState) ----------------

class AlertsHistoryScreen extends StatelessWidget {
  final String patientId;
  const AlertsHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final alerts = app.getAlertsForPatient(patientId)..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts History'),
        backgroundColor: PETROL_DARK,
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('No alerts.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) => _AlertTile(alert: alerts[index]),
            ),
    );
  }
}

// ---------------- SHARED WIDGETS ----------------

class _VitalListTile extends StatelessWidget {
  final VitalSample v;
  const _VitalListTile({required this.v});

  @override
  Widget build(BuildContext context) {
    final date = '${v.timestamp.day.toString().padLeft(2, '0')}/${v.timestamp.month.toString().padLeft(2, '0')}';
    final time = '${v.timestamp.hour.toString().padLeft(2, '0')}:${v.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_heart, color: PETROL),
        title: Text('HR: ${v.hr} bpm • SpO₂: ${v.spo2}%'),
        subtitle: Text(
          'Glu: ${v.glucose ?? '-'} mg/dL • Temp: ${v.temperature?.toStringAsFixed(1) ?? '-'} °C\n$date • $time',
        ),
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  final Medication med;
  const _MedicationTile({required this.med});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication, color: Color(0xFF3B82F6)),
        title: Text(med.name),
        subtitle: Text('${med.dosage} • ${med.frequency}'),
        trailing: med.active
            ? const Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            : const Text('Inactive'),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertItem alert;
  const _AlertTile({required this.alert});

  Color _severityColor() {
    switch (alert.severity.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = '${alert.timestamp.day.toString().padLeft(2, '0')}/${alert.timestamp.month.toString().padLeft(2, '0')}';
    final time = '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: Icon(Icons.warning, color: _severityColor()),
        title: Text(alert.message),
        subtitle: Text('$date • $time'),
        trailing: Text(
          alert.severity.toUpperCase(),
          style: TextStyle(
            color: _severityColor(),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  final MoodRecord mood;
  const _MoodTile({required this.mood});

  @override
  Widget build(BuildContext context) {
    final date = '${mood.timestamp.day.toString().padLeft(2, '0')}/${mood.timestamp.month.toString().padLeft(2, '0')}';
    final time = '${mood.timestamp.hour.toString().padLeft(2, '0')}:${mood.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.emoji_emotions, color: PETROL),
        title: Text(mood.mood),
        subtitle: Text(
          '${mood.note ?? ''}\n$date • $time',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
