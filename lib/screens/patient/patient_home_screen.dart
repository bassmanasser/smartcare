import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dispatch_decision.dart';
import '../../models/patient.dart';
import '../../models/risk_assessment.dart';
import '../../models/vital_sample.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/glucose_advisor.dart';
import '../../utils/localization.dart';

import 'ai_bot_screen.dart';
import 'alerts_history_screen.dart';
import 'arrhythmia_check_screen.dart';
import 'charts_screen.dart';
import 'doctor_notes_screen.dart';
import 'medication_screen.dart';
import 'mood_screen.dart';
import 'patient_doctor_search_screen.dart';
import 'report_screen.dart';
import 'respiratory_test_screen.dart';
import 'settings_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final Patient patient;

  const PatientHomeScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = Provider.of<AppState>(context, listen: false);
      await app.fetchHistory(widget.patient.id);
      await app.connectDevice(widget.patient.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    final tabs = [
      _PatientDispatchHomeTab(patient: widget.patient),
      _PatientServicesTab(patient: widget.patient),
      const PatientDoctorSearchScreen(),
      PatientSettingsScreen(
        patientId: widget.patient.id,
        onLogout: () async {
          final app = Provider.of<AppState>(context, listen: false);
          await app.disconnectDevice();
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
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
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
              label: 'Doctors',
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

class _PatientDispatchHomeTab extends StatelessWidget {
  final Patient patient;

  const _PatientDispatchHomeTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Consumer<AppState>(
      builder: (context, app, child) {
        final vitals = app.vitals;
        final VitalSample? latest = vitals.isNotEmpty ? vitals.last : null;

        final assessment = app.currentAssessment;
        final dispatch = app.currentDispatch;

        final bool isMeasuringGlucose =
            latest != null && (latest.glucose == 0 || latest.glucose == 0.0);

        final glucoseText = latest == null
            ? '--'
            : isMeasuringGlucose
                ? app.glucoseStatusMsg
                : latest.glucose.toInt().toString();

        final glucoseUnit = isMeasuringGlucose ? '' : 'mg/dL';
        final advice = GlucoseAdvisor.getAdvice(latest?.glucose ?? 0.0);

        return Scaffold(
          backgroundColor: const Color(0xffF6F8FB),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await app.fetchHistory(patient.id);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PatientHeader(
                      patient: patient,
                      isConnected: app.isDeviceConnected,
                      deviceStatus: app.deviceStatus,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _RiskSummaryCard(
                        assessment: assessment,
                        caseStatus: app.caseStatus,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _DispatchDecisionCard(
                        specialty: dispatch?.specialty ?? 'general',
                        urgency: dispatch?.urgency.key ?? 'routine',
                        action: dispatch?.action.key ?? 'self_care',
                        explanation: dispatch?.explanation ??
                            'No immediate dispatch recommendation yet.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _QuickFlagsRow(
                        arrhythmiaAbnormal: app.arrhythmiaAbnormal,
                        respiratoryAbnormal: app.respiratoryAbnormal,
                        alertsCount: app.alerts.length,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Live Vital Signs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: PETROL_DARK,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _VitalCard(
                                  icon: Icons.favorite_rounded,
                                  title: lang.translate('hr'),
                                  value: '${latest?.hr ?? '--'}',
                                  unit: 'bpm',
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _VitalCard(
                                  icon: Icons.air_rounded,
                                  title: lang.translate('spo2'),
                                  value: '${latest?.spo2 ?? '--'}',
                                  unit: '%',
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
                                  icon: Icons.monitor_heart_rounded,
                                  title: lang.translate('bp'),
                                  value:
                                      '${latest?.sys ?? '--'}/${latest?.dia ?? '--'}',
                                  unit: 'mmHg',
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _VitalCard(
                                  icon: Icons.bloodtype_rounded,
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
                            icon: Icons.thermostat_rounded,
                            title: 'Temperature',
                            value: latest == null
                                ? '--'
                                : latest.temperature.toStringAsFixed(1),
                            unit: '°C',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    if (!isMeasuringGlucose &&
                        latest != null &&
                        latest.glucose > 0) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _AdviceCard(advice: advice as String),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ReasonBreakdownCard(
                        assessment: assessment,
                        latest: latest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MiniTimelineCard(
                        latest: latest,
                        assessment: assessment,
                        alertsCount: app.alerts.length,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PatientServicesTab extends StatelessWidget {
  final Patient patient;

  const _PatientServicesTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    final services = [
      _Svc(
        lang.translate('reports'),
        Icons.picture_as_pdf_rounded,
        Colors.red.shade700,
        (_) => ReportScreen(patientId: patient.id, patientName: patient.name),
      ),
      _Svc(
        lang.translate('doctor_notes'),
        Icons.note_alt_rounded,
        Colors.indigo,
        (_) => DoctorNotesScreen(patientId: patient.id),
      ),
      _Svc(
        lang.translate('medications'),
        Icons.medication_rounded,
        Colors.blue,
        (_) => MedicationScreen(patientId: patient.id),
      ),
      _Svc(
        lang.translate('mood'),
        Icons.mood_rounded,
        Colors.orange,
        (_) => MoodScreen(patientId: patient.id),
      ),
      _Svc(
        'Charts',
        Icons.show_chart_rounded,
        Colors.green,
        (_) => ChartsScreen(patientId: patient.id),
      ),
      _Svc(
        lang.translate('alerts_history'),
        Icons.history_rounded,
        Colors.redAccent,
        (_) => AlertsHistoryScreen(patientId: patient.id),
      ),
      _Svc(
        'Arrhythmia Check',
        Icons.favorite_rounded,
        Colors.red,
        (_) => ArrhythmiaCheckScreen(patientId: patient.id),
      ),
      _Svc(
        'Resp. Check',
        Icons.graphic_eq_rounded,
        Colors.teal,
        (_) => const RespiratoryTestScreen(),
      ),
      _Svc(
        lang.translate('ai_bot'),
        Icons.smart_toy_rounded,
        Colors.purple,
        (_) => AiBotScreen(patient: patient),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(
        title: Text(lang.translate('services')),
        centerTitle: true,
        backgroundColor: PETROL_DARK,
        automaticallyImplyLeading: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.03,
        ),
        itemBuilder: (context, i) {
          final item = services[i];
          return GestureDetector(
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: item.builder)),
            child: Container(
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
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 30, color: item.color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
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

class _PatientHeader extends StatelessWidget {
  final Patient patient;
  final bool isConnected;
  final String deviceStatus;

  const _PatientHeader({
    required this.patient,
    required this.isConnected,
    required this.deviceStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: PETROL_DARK,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
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
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              _ConnectionBadge(
                connected: isConnected,
                text: isConnected ? 'Connected' : 'Disconnected',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_connected_rounded,
                    color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    deviceStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Age: ${patient.age}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskSummaryCard extends StatelessWidget {
  final RiskAssessment? assessment;
  final String caseStatus;

  const _RiskSummaryCard({
    required this.assessment,
    required this.caseStatus,
  });

  @override
  Widget build(BuildContext context) {
    final level = assessment?.riskLevel ?? RiskLevel.normal;
    final score = assessment?.score ?? 0;
    final color = _riskColor(level);
    final label = _riskLabel(level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.95),
            color.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Health Status',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Score $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Case status: $caseStatus',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DispatchDecisionCard extends StatelessWidget {
  final String specialty;
  final String urgency;
  final String action;
  final String explanation;

  const _DispatchDecisionCard({
    required this.specialty,
    required this.urgency,
    required this.action,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Medical Dispatch',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.local_hospital_rounded,
                  title: 'Specialty',
                  value: _prettyText(specialty),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  icon: Icons.priority_high_rounded,
                  title: 'Urgency',
                  value: _prettyText(urgency),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoPill(
            icon: Icons.route_rounded,
            title: 'Action',
            value: _prettyText(action),
            wide: true,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffF6F8FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              explanation,
              style: const TextStyle(
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFlagsRow extends StatelessWidget {
  final bool arrhythmiaAbnormal;
  final bool respiratoryAbnormal;
  final int alertsCount;

  const _QuickFlagsRow({
    required this.arrhythmiaAbnormal,
    required this.respiratoryAbnormal,
    required this.alertsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FlagCard(
            title: 'Arrhythmia',
            value: arrhythmiaAbnormal ? 'Abnormal' : 'Normal',
            color: arrhythmiaAbnormal ? Colors.red : Colors.green,
            icon: Icons.favorite_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FlagCard(
            title: 'Respiratory',
            value: respiratoryAbnormal ? 'Abnormal' : 'Normal',
            color: respiratoryAbnormal ? Colors.orange : Colors.green,
            icon: Icons.air_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FlagCard(
            title: 'Alerts',
            value: '$alertsCount',
            color: alertsCount > 0 ? Colors.purple : Colors.green,
            icon: Icons.notifications_active_rounded,
          ),
        ),
      ],
    );
  }
}

class _ReasonBreakdownCard extends StatelessWidget {
  final RiskAssessment? assessment;
  final VitalSample? latest;

  const _ReasonBreakdownCard({
    required this.assessment,
    required this.latest,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = assessment?.reasons ?? const <String>[];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why this recommendation?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 12),
          if (reasons.isEmpty)
            const Text(
              'No abnormal reason detected yet. The system is still monitoring incoming data.',
              style: TextStyle(height: 1.4),
            )
          else
            ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: PETROL,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (latest != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniReadingChip(label: 'HR', value: '${latest!.hr} bpm'),
                _MiniReadingChip(label: 'SpO2', value: '${latest!.spo2}%'),
                _MiniReadingChip(
                  label: 'BP',
                  value: '${latest!.sys}/${latest!.dia}',
                ),
                _MiniReadingChip(
                  label: 'Temp',
                  value: '${latest!.temperature.toStringAsFixed(1)}°C',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniTimelineCard extends StatelessWidget {
  final VitalSample? latest;
  final RiskAssessment? assessment;
  final int alertsCount;

  const _MiniTimelineCard({
    required this.latest,
    required this.assessment,
    required this.alertsCount,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Care Timeline Snapshot',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 14),
          _TimelineRow(
            title: 'Latest reading received',
            subtitle: latest == null
                ? 'No live reading yet'
                : 'Heart rate ${latest!.hr} bpm, SpO2 ${latest!.spo2}%, Temp ${latest!.temperature.toStringAsFixed(1)}°C',
            icon: Icons.monitor_heart_rounded,
          ),
          _TimelineRow(
            title: 'Risk assessment generated',
            subtitle: assessment == null
                ? 'Pending'
                : '${_riskLabel(assessment!.riskLevel)} — Score ${assessment!.score}',
            icon: Icons.analytics_rounded,
          ),
          _TimelineRow(
            title: 'Alerts in system',
            subtitle: '$alertsCount active/recent alerts',
            icon: Icons.warning_amber_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String advice;

  const _AdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              advice,
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color color;

  const _VitalCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(title),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value $unit',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
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
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool wide;

  const _InfoPill({
    required this.icon,
    required this.title,
    required this.value,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: PETROL_DARK),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: PETROL_DARK,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _FlagCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final bool connected;
  final String text;

  const _ConnectionBadge({
    required this.connected,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniReadingChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniReadingChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: PETROL_DARK,
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLast;

  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PETROL.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: PETROL_DARK, size: 20),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: Colors.black12,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _riskLabel(RiskLevel level) {
  switch (level) {
    case RiskLevel.normal:
      return 'Normal';
    case RiskLevel.attention:
      return 'Attention Needed';
    case RiskLevel.highRisk:
      return 'High Risk';
    case RiskLevel.emergency:
      return 'Emergency';
  }
}

Color _riskColor(RiskLevel level) {
  switch (level) {
    case RiskLevel.normal:
      return Colors.green;
    case RiskLevel.attention:
      return Colors.orange;
    case RiskLevel.highRisk:
      return Colors.deepOrange;
    case RiskLevel.emergency:
      return Colors.red;
  }
}

String _prettyText(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}