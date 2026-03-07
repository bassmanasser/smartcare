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
import 'patient_doctor_search_screen.dart';

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
      final app = Provider.of<AppState>(context, listen: false);
      app.fetchHistory(widget.patient.id);

      // يفضل تعملي reconnect لو محتاجة فقط
      app.connectDevice(widget.patient.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    final tabs = [
      _PatientHomeTab(patient: widget.patient),
      _PatientServicesTab(patient: widget.patient),
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
      backgroundColor: const Color(0xFFF6F8FB),
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: PETROL,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: lang.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: lang.translate('services'),
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_search_rounded),
              label: "Doctors",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: lang.translate('settings'),
            ),
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

        final bool isMeasuringGlucose =
            (v != null && (v.glucose == 0 || v.glucose == 0.0));

        final String glucoseText = (v == null)
            ? '--'
            : isMeasuringGlucose
                ? app.glucoseStatusMsg
                : v.glucose.toInt().toString();

        final String glucoseUnit = isMeasuringGlucose ? '' : 'mg/dL';
        final String tempText =
            (v == null) ? '--' : v.temperature.toStringAsFixed(1);

        final advice = GlucoseAdvisor.getAdvice(v?.glucose ?? 0.0);

        final doctors =
            app.doctors?.values.where((d) => d.id == patient.doctorId).toList() ??
                [];

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await app.fetchHistory(patient.id);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, patient, app, lang),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHealthOverview(v, glucoseText, glucoseUnit, tempText),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildQuickActions(context, patient),
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "طاقمي الطبي",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PETROL_DARK,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCareTeam(doctors),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      lang.translate('home'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PETROL_DARK,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildVitalsSection(lang, v, glucoseText, glucoseUnit, tempText),
                  ),

                  if (!isMeasuringGlucose && v != null && v.glucose > 0) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildAdviceCard(advice.toString()),
                    ),
                  ],

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildEmergencyCard(context),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Patient patient,
    AppState app,
    AppLocalizations lang,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [PETROL_DARK, PETROL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${lang.translate('age')}: ${patient.age}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _buildConnectionStatus(app),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    app.isDeviceConnected
                        ? "Your device is connected and monitoring is active"
                        : "Device is disconnected, reconnect to continue monitoring",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(AppState app) {
    final connected = app.isDeviceConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: connected
            ? Colors.greenAccent.withOpacity(0.18)
            : Colors.redAccent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: connected ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 14,
            color: connected ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 5),
          Text(
            connected ? "Connected" : "Disconnected",
            style: TextStyle(
              color: connected ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthOverview(
    VitalSample? v,
    String glucoseText,
    String glucoseUnit,
    String tempText,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatusCard(
            title: "Heart Rate",
            value: "${v?.hr ?? '--'}",
            subtitle: "bpm",
            icon: Icons.favorite_rounded,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatusCard(
            title: "SpO2",
            value: "${v?.spo2 ?? '--'}",
            subtitle: "%",
            icon: Icons.water_drop_rounded,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatusCard(
            title: "Temp",
            value: tempText,
            subtitle: "°C",
            icon: Icons.thermostat_rounded,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PETROL_DARK,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.picture_as_pdf_rounded,
                label: "Reports",
                color: Colors.red.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(
                        patientId: patient.id,
                        patientName: patient.name,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.medication_rounded,
                label: "Medications",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicationScreen(patientId: patient.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.note_alt_rounded,
                label: "Doctor Notes",
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorNotesScreen(patientId: patient.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.show_chart_rounded,
                label: "Charts",
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChartsScreen(patientId: patient.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCareTeam(List doctors) {
    if (doctors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.person_off_rounded, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "لا يوجد طبيب مرتبط حالياً",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        itemBuilder: (context, i) {
          final d = doctors[i];
          return Container(
            width: 230,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: PETROL.withOpacity(0.12),
                  child: const Icon(Icons.person, color: PETROL_DARK),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        d.name ?? "Doctor",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.specialty ?? "Specialist",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Linked",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVitalsSection(
    AppLocalizations lang,
    VitalSample? v,
    String glucoseText,
    String glucoseUnit,
    String tempText,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _VitalCard(
                icon: Icons.favorite,
                title: lang.translate('hr'),
                value: "${v?.hr ?? '--'}",
                unit: "bpm",
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalCard(
                icon: Icons.water_drop,
                title: lang.translate('spo2'),
                value: "${v?.spo2 ?? '--'}",
                unit: "%",
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _VitalCard(
                icon: Icons.compress_rounded,
                title: lang.translate('bp'),
                value: "${v?.sys ?? '--'}/${v?.dia ?? '--'}",
                unit: "mmHg",
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalCard(
                icon: Icons.monitor_weight_rounded,
                title: lang.translate('glucose'),
                value: glucoseText,
                unit: glucoseUnit,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _VitalCard(
          icon: Icons.thermostat,
          title: "Temperature",
          value: tempText,
          unit: "°C",
          color: Colors.orange,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildAdviceCard(String advice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              advice,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Icon(Icons.emergency_rounded, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emergency Help",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Use this section to quickly alert or contact support in critical situations.",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Emergency"),
                  content: const Text(
                    "اعملي هنا بعد كده ربط حقيقي مع زر طوارئ أو إرسال تنبيه للدكتور/الولي.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              "Alert",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// 🧩 TAB 2: SERVICES
// ==================================================================

class _PatientServicesTab extends StatelessWidget {
  final Patient patient;
  const _PatientServicesTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    final services = [
      _Svc(
        lang.translate('reports'),
        Icons.picture_as_pdf,
        Colors.red.shade700,
        (_) => ReportScreen(patientId: patient.id, patientName: patient.name),
      ),
      _Svc(
        lang.translate('doctor_notes'),
        Icons.note_alt,
        Colors.indigo,
        (_) => DoctorNotesScreen(patientId: patient.id),
      ),
      _Svc(
        lang.translate('medications'),
        Icons.medication,
        Colors.blue,
        (_) => MedicationScreen(patientId: patient.id),
      ),
      _Svc(
        lang.translate('mood'),
        Icons.emoji_emotions,
        Colors.orange,
        (_) => MoodScreen(patientId: patient.id),
      ),
      _Svc(
        "Charts",
        Icons.show_chart,
        Colors.green,
        (_) => ChartsScreen(patientId: patient.id),
      ),
      _Svc(
        lang.translate('alerts_history'),
        Icons.history,
        Colors.redAccent,
        (_) => AlertsHistoryScreen(patientId: patient.id),
      ),
      _Svc(
        'Arrhythmia Check',
        Icons.favorite,
        Colors.red,
        (_) => ArrhythmiaCheckScreen(patientId: patient.id),
      ),
      _Svc(
        "Resp. Check",
        Icons.graphic_eq,
        Colors.teal,
        (_) => const RespiratoryTestScreen(),
      ),
      _Svc(
        lang.translate('ai_bot'),
        Icons.smart_toy,
        Colors.purple,
        (_) => AiBotScreen(patient: patient),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(lang.translate('services')),
        backgroundColor: PETROL_DARK,
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, i) {
            final svc = services[i];
            return GestureDetector(
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: svc.builder)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: svc.color.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          svc.icon,
                          size: 30,
                          color: svc.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        svc.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
  final bool fullWidth;

  const _VitalCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "$value $unit",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: PETROL_DARK,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MiniStatusCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: PETROL_DARK,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}