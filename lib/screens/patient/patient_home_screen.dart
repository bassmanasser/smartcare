import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import '../../models/patient.dart';
import '../../models/vital_sample.dart';
import '../../providers/app_state.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

// Glucose Advisor
import '../../utils/glucose_advisor.dart';

// Screens
import 'ai_bot_screen.dart';
import 'charts_screen.dart';
import 'settings_screen.dart';
import 'mood_screen.dart';
import 'alerts_history_screen.dart';
import 'medication_screen.dart';
import 'doctor_notes_screen.dart';
import 'report_screen.dart';
import 'arrhythmia_check_screen.dart';
import 'respiratory_test_screen.dart';
import 'patient_doctor_search_screen.dart'; // ✅ شاشة بحث الدكاترة (هتبقى Tab لوحدها)

class PatientHomeScreen extends StatefulWidget {
  final Patient patient;
  const PatientHomeScreen({super.key, required this.patient});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchHistory(widget.patient.id);
      Provider.of<AppState>(context, listen: false).connectDevice(widget.patient.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    // ✅ Tabs بعد التعديل: Home / Services / Doctors / Settings
    final tabs = [
      _PatientHomeTab(patient: widget.patient),
      _PatientServicesTab(patient: widget.patient),

      // ✅ Tab جديدة للدكاترة (بدل ما تكون زر جوه Services)
      const PatientDoctorSearchScreen(),

      PatientSettingsScreen(
        patientId: widget.patient.id,
        onLogout: () async {
          final auth = Provider.of<AuthService>(context, listen: false);
          await Provider.of<AppState>(context, listen: false).disconnectDevice();
          await auth.signOut(context);
        },
      ),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: PETROL,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: lang.translate('home')),
            BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: lang.translate('services')),

            // ✅ Doctors Tab
            const BottomNavigationBarItem(icon: Icon(Icons.person_search), label: "Doctors"),

            BottomNavigationBarItem(icon: const Icon(Icons.settings), label: lang.translate('settings')),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// 🏠 TAB 1: HOME
// ==================================================================

class _PatientHomeTab extends StatelessWidget {
  final Patient patient;
  const _PatientHomeTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Consumer<AppState>(
      builder: (context, app, child) {
        final vitalsList = app.vitals;
        final VitalSample? v = vitalsList.isNotEmpty ? vitalsList.last : null;

        final bool isMeasuringGlucose = (v != null && (v.glucose == 0 || v.glucose == 0.0));

        final String glucoseText = (v == null)
            ? '--'
            : isMeasuringGlucose
                ? app.glucoseStatusMsg
                : v.glucose.toInt().toString();

        final String glucoseUnit = isMeasuringGlucose ? '' : 'mg/dL';
        final String tempText = (v == null) ? '--' : v.temperature.toStringAsFixed(1);
        final advice = GlucoseAdvisor.getAdvice(v?.glucose ?? 0.0);

        // جلب بيانات الدكتور المرتبط
        final doctors = app.doctors?.values.where((d) => d.id == patient.doctorId).toList() ?? [];

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  decoration: const BoxDecoration(
                    color: PETROL_DARK,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.translate('app_title'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          _buildConnectionStatus(app),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildUserInfo(patient, lang),
                    ],
                  ),
                ),

                // Care Team
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text("طاقمي الطبي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PETROL_DARK)),
                ),
                _buildCareTeam(doctors),

                // Vitals Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _VitalCard(icon: Icons.favorite, title: lang.translate('hr'), value: "${v?.hr ?? '--'}", unit: "bpm", color: Colors.red)),
                        const SizedBox(width: 10),
                        Expanded(child: _VitalCard(icon: Icons.water_drop, title: lang.translate('spo2'), value: "${v?.spo2 ?? '--'}", unit: "%", color: Colors.blue)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _VitalCard(icon: Icons.compress, title: lang.translate('bp'), value: "${v?.sys ?? '--'}/${v?.dia ?? '--'}", unit: "mmHg", color: Colors.purple)),
                        const SizedBox(width: 10),
                        Expanded(child: _VitalCard(icon: Icons.monitor_weight, title: lang.translate('glucose'), value: glucoseText, unit: glucoseUnit, color: Colors.teal)),
                      ]),
                      const SizedBox(height: 10),
                      _VitalCard(icon: Icons.thermostat, title: "Temperature", value: tempText, unit: "°C", color: Colors.orange),

                      if (!isMeasuringGlucose && v != null && v.glucose > 0) ...[
                        const SizedBox(height: 10),
                        _buildAdviceCard(advice as String),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus(AppState app) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: app.isDeviceConnected ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: app.isDeviceConnected ? Colors.greenAccent : Colors.redAccent),
      ),
      child: Text(
        app.isDeviceConnected ? "Connected" : "Disconnected",
        style: TextStyle(
          color: app.isDeviceConnected ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildUserInfo(Patient patient, AppLocalizations lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(patient.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("${lang.translate('age')}: ${patient.age}", style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildCareTeam(List doctors) {
    if (doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text("لا يوجد طبيب مرتبط حالياً", style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: doctors.length,
        itemBuilder: (context, i) {
          final d = doctors[i];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(d.specialty ?? "", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdviceCard(String advice) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(child: Text(advice)),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// 🧩 TAB 2: SERVICES (تم إزالة زر بحث الطبيب)
// ==================================================================

class _PatientServicesTab extends StatelessWidget {
  final Patient patient;
  const _PatientServicesTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    final services = [
      // ❌ اتشال: بحث عن طبيب (بقى Tab لوحده)
      _Svc(lang.translate('reports'), Icons.picture_as_pdf, Colors.red.shade700, (_) => ReportScreen(patientId: patient.id, patientName: patient.name)),
      _Svc(lang.translate('doctor_notes'), Icons.note_alt, Colors.indigo, (_) => DoctorNotesScreen(patientId: patient.id)),
      _Svc(lang.translate('medications'), Icons.medication, Colors.blue, (_) => MedicationScreen(patientId: patient.id)),
      _Svc(lang.translate('mood'), Icons.emoji_emotions, Colors.orange, (_) => MoodScreen(patientId: patient.id)),
      _Svc("Charts", Icons.show_chart, Colors.green, (_) => ChartsScreen(patientId: patient.id)),
      _Svc(lang.translate('alerts_history'), Icons.history, Colors.redAccent, (_) => AlertsHistoryScreen(patientId: patient.id)),
      _Svc('Arrhythmia Check', Icons.favorite, Colors.red, (_) => ArrhythmiaCheckScreen(patientId: patient.id)),
      _Svc("Resp. Check", Icons.graphic_eq, Colors.teal, (_) => const RespiratoryTestScreen()),
      _Svc(lang.translate('ai_bot'), Icons.smart_toy, Colors.purple, (_) => AiBotScreen(patient: patient)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('services')),
        backgroundColor: PETROL_DARK,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: services[i].builder)),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: services[i].color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(services[i].icon, size: 32, color: services[i].color),
                  ),
                  const SizedBox(height: 12),
                  Text(services[i].title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Svc {
  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  _Svc(this.title, this.icon, this.color, this.builder);
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color color;
  const _VitalCard({required this.icon, required this.title, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(title),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("$value $unit", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}