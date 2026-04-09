import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../models/risk_assessment.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

import 'ai_bot_screen.dart';
import 'alerts_history_screen.dart';
import 'arrhythmia_check_screen.dart';
import 'care_team_screen.dart';
import 'charts_screen.dart';
import 'doctor_notes_screen.dart';
import 'medication_screen.dart';
import 'mood_screen.dart';
import 'patient_profile_screen.dart';
import 'patient_qr_screen.dart';
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
      PatientProfileScreen(patient: widget.patient),
      _PatientServicesTab(patient: widget.patient),
      PatientSettingsScreen(
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        onLogout: () async {
          final app = Provider.of<AppState>(context, listen: false);
          await app.disconnectDevice();
          await FirebaseAuth.instance.signOut();
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: lang.translate('services'),
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
    return Consumer<AppState>(
      builder: (context, app, child) {
        final assessment = app.currentAssessment;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(patient.id)
              .snapshots(),
          builder: (context, snapshot) {
            final liveData = snapshot.data?.data() ?? {};

            final livePatient = patient.copyWith(
              assignedInstitutionId:
                  liveData['assignedInstitutionId']?.toString(),
              assignedInstitutionCode:
                  liveData['assignedInstitutionCode']?.toString(),
              assignedInstitutionName:
                  liveData['assignedInstitutionName']?.toString(),
              assignedDepartment: liveData['assignedDepartment']?.toString(),
              assignedDoctorUid: liveData['assignedDoctorUid']?.toString(),
              queuePriority: liveData['queuePriority']?.toString(),
              workflowStage: liveData['workflowStage']?.toString(),
            );

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
                          patient: livePatient,
                          isConnected: app.isDeviceConnected,
                          deviceStatus: app.deviceStatus,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _InstitutionWorkflowCard(patient: livePatient),
                        ),
                        const SizedBox(height: 12),
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
                          child: _QuickFlagsRow(
                            arrhythmiaAbnormal: app.arrhythmiaAbnormal,
                            respiratoryAbnormal: app.respiratoryAbnormal,
                            alertsCount: app.alerts.length,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _PatientShortcutsCard(patient: livePatient),
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
        'My QR Code',
        Icons.qr_code_rounded,
        Colors.teal,
        (_) => PatientQrScreen(patient: patient),
      ),
      _Svc(
        'Care Team',
        Icons.groups_rounded,
        Colors.deepPurple,
        (_) => CareTeamScreen(
          institutionId: patient.assignedInstitutionId ?? '',
        ),
      ),
      _Svc(
        lang.translate('reports'),
        Icons.picture_as_pdf_rounded,
        Colors.red,
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

class _InstitutionWorkflowCard extends StatelessWidget {
  final Patient patient;

  const _InstitutionWorkflowCard({required this.patient});

  Color _priorityColor(String value) {
    switch (value) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.deepOrange;
      case 'high':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final institution = patient.assignedInstitutionName ??
        patient.assignedInstitutionCode ??
        'Not assigned yet';
    final department = patient.assignedDepartment ?? 'Pending triage';
    final stage = patient.workflowStage ?? 'patient_intake';
    final priority = patient.queuePriority ?? 'routine';

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Institution Workflow',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 14),
          _kv('Institution', institution),
          const SizedBox(height: 8),
          _kv('Department', department),
          const SizedBox(height: 8),
          _kv('Stage', _prettyText(stage)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Queue Priority:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PETROL_DARK,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _priorityColor(priority).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _prettyText(priority),
                  style: TextStyle(
                    color: _priorityColor(priority),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: PETROL_DARK,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

class _PatientShortcutsCard extends StatelessWidget {
  final Patient patient;

  const _PatientShortcutsCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Access',
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
                child: _shortcut(
                  context,
                  icon: Icons.groups_rounded,
                  label: 'Care Team',
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CareTeamScreen(
                          institutionId: patient.assignedInstitutionId ?? '',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _shortcut(
                  context,
                  icon: Icons.qr_code_rounded,
                  label: 'My QR',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientQrScreen(patient: patient),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shortcut(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: PETROL_DARK,
              ),
            ),
          ],
        ),
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