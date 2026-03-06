import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/doctor_note.dart';
import '../../models/patient.dart';
import '../../models/vital_sample.dart';
import '../../models/alert_item.dart';
import '../../providers/app_state.dart';
import '../../services/pdf_report_service.dart';
import '../../utils/constants.dart';

class PatientDetailForDoctorScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailForDoctorScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailForDoctorScreen> createState() =>
      _PatientDetailForDoctorScreenState();
}

class _PatientDetailForDoctorScreenState
    extends State<PatientDetailForDoctorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _noteCtrl = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = Provider.of<AppState>(context, listen: false);
      await app.fetchHistory(widget.patient.id);
      await app.fetchAlerts(widget.patient.id);
      await app.fetchDoctorNotes(widget.patient.id);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _textOrNA(String? value, {String fallback = "Not available"}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  String _listOrNA(List<String>? items, {String fallback = "None"}) {
    if (items == null || items.isEmpty) return fallback;
    final cleaned = items.where((e) => e.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return fallback;
    return cleaned.join(", ");
  }

  String _genderText(String gender) {
    final g = gender.trim();
    return g.isEmpty ? "Unknown" : g;
  }

  String _birthDateText(DateTime? date) {
    if (date == null) return "Not available";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _patientShortId(String id) {
    if (id.trim().isEmpty) return "N/A";
    return id.length <= 10 ? id : id.substring(0, 10);
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "Not available";
    return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _exportPdf(AppState app) async {
    try {
      await PdfReportService.generateAndShareReport(widget.patient, app);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تصدير التقرير بنجاح ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل تصدير التقرير: $e")),
      );
    }
  }

  void _showPrescriptionDialog() {
    final medNameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "إضافة روشتة علاجية",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _inputField(
                  controller: medNameCtrl,
                  label: "اسم الدواء",
                  icon: Icons.medication_outlined,
                ),
                const SizedBox(height: 12),
                _inputField(
                  controller: dosageCtrl,
                  label: "الجرعة",
                  hint: "مثال: قرص كل 12 ساعة",
                  icon: Icons.medical_services_outlined,
                ),
                const SizedBox(height: 12),
                _inputField(
                  controller: durationCtrl,
                  label: "المدة",
                  hint: "مثال: 5 أيام",
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 12),
                _inputField(
                  controller: notesCtrl,
                  label: "ملاحظات إضافية",
                  hint: "مثال: بعد الأكل",
                  icon: Icons.note_alt_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL_DARK,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final med = medNameCtrl.text.trim();
                      final dose = dosageCtrl.text.trim();
                      final duration = durationCtrl.text.trim();
                      final extra = notesCtrl.text.trim();

                      if (med.isEmpty || dose.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text("من فضلك املئي اسم الدواء والجرعة"),
                          ),
                        );
                        return;
                      }

                      final rxText = [
                        "=== Digital Prescription ===",
                        "Medicine: $med",
                        "Dose: $dose",
                        if (duration.isNotEmpty) "Duration: $duration",
                        if (extra.isNotEmpty) "Notes: $extra",
                        "Date: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}",
                      ].join("\n");

                      _noteCtrl.text = rxText;

                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("تم تجهيز الروشتة داخل خانة الملاحظات ✅"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "إضافة للروشتة",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveDoctorNote(AppState app) {
    final text = _noteCtrl.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("اكتبي الملاحظة أولاً")),
      );
      return;
    }

    final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final newNote = DoctorNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patient.id,
      doctorId: doctorId,
      text: text,
      date: DateTime.now(),
    );

    app.addDoctorNote(newNote);

    _noteCtrl.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم حفظ الملاحظة بنجاح ✅")),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: PETROL_DARK, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _summaryMiniCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PETROL.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: PETROL_DARK),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PETROL.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: PETROL_DARK),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicalBlock({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PETROL.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: PETROL_DARK),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vitalTile({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (color ?? PETROL_DARK).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? PETROL_DARK),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _overviewTab(List<DoctorNote> notes) {
    final p = widget.patient;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("Patient Summary", icon: Icons.dashboard_outlined),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryMiniCard(
                title: "Age",
                value: "${p.age}",
                icon: Icons.cake_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryMiniCard(
                title: "Gender",
                value: _genderText(p.gender),
                icon: Icons.wc_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryMiniCard(
                title: "Blood Type",
                value: _textOrNA(p.bloodType, fallback: "Unknown"),
                icon: Icons.bloodtype_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryMiniCard(
                title: "Notes",
                value: "${notes.length}",
                icon: Icons.note_alt_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle("Basic Information", icon: Icons.person_outline),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.badge_outlined,
          title: "Patient ID",
          value: _patientShortId(p.id),
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.email_outlined,
          title: "Email",
          value: _textOrNA(p.email, fallback: "No email"),
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.phone_outlined,
          title: "Phone",
          value: _textOrNA(p.phone, fallback: "No phone"),
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.calendar_today_outlined,
          title: "Birth Date",
          value: _birthDateText(p.birthDate),
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.height_outlined,
          title: "Height",
          value: _textOrNA(p.height, fallback: "Not set"),
        ),
        const SizedBox(height: 10),
        _infoCard(
          icon: Icons.monitor_weight_outlined,
          title: "Weight",
          value: _textOrNA(p.weight, fallback: "Not set"),
        ),
      ],
    );
  }

  Widget _medicalTab() {
    final p = widget.patient;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("Medical Information", icon: Icons.medical_information_outlined),
        const SizedBox(height: 10),
        _medicalBlock(
          title: "Blood Type",
          value: _textOrNA(p.bloodType, fallback: "Unknown"),
          icon: Icons.bloodtype_outlined,
        ),
        const SizedBox(height: 12),
        _medicalBlock(
          title: "Allergies",
          value: _listOrNA(p.allergies, fallback: "No allergies recorded"),
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 12),
        _medicalBlock(
          title: "Chronic Diseases",
          value: _listOrNA(
            p.chronicDiseases,
            fallback: "No chronic diseases recorded",
          ),
          icon: Icons.health_and_safety_outlined,
        ),
        const SizedBox(height: 12),
        _medicalBlock(
          title: "Current Medications",
          value: _listOrNA(
            p.currentMedications,
            fallback: "No current medications recorded",
          ),
          icon: Icons.medication_liquid_outlined,
        ),
        const SizedBox(height: 20),
        _sectionTitle("Emergency Contact", icon: Icons.contact_phone_outlined),
        const SizedBox(height: 10),
        _medicalBlock(
          title: "Contact Name",
          value: _textOrNA(
            p.emergencyContactName,
            fallback: "No emergency contact name",
          ),
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _medicalBlock(
          title: "Contact Phone",
          value: _textOrNA(
            p.emergencyContactPhone,
            fallback: "No emergency contact phone",
          ),
          icon: Icons.phone_in_talk_outlined,
        ),
      ],
    );
  }

  Widget _vitalsTab(AppState app) {
    final VitalSample? latest = app.getLatestVitals(widget.patient.id);
    final history = app.getVitalsForPatient(widget.patient.id).reversed.toList();

    if (latest == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Latest Vitals", icon: Icons.monitor_heart_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text("لا توجد قراءات متاحة لهذا المريض حالياً"),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("Latest Vitals", icon: Icons.monitor_heart_outlined),
        const SizedBox(height: 10),
        _vitalTile(
          title: "Heart Rate",
          value: "${latest.hr} bpm",
          icon: Icons.favorite_outline,
          color: Colors.red,
        ),
        const SizedBox(height: 10),
        _vitalTile(
          title: "SpO2",
          value: "${latest.spo2} %",
          icon: Icons.air_outlined,
          color: Colors.blue,
        ),
        const SizedBox(height: 10),
        _vitalTile(
          title: "Blood Pressure",
          value: "${latest.sys}/${latest.dia} mmHg",
          icon: Icons.speed_outlined,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 10),
        _vitalTile(
          title: "Glucose",
          value: "${latest.glucose.toStringAsFixed(1)} mg/dL",
          icon: Icons.water_drop_outlined,
          color: Colors.orange,
        ),
        const SizedBox(height: 10),
        _vitalTile(
          title: "Temperature",
          value: "${latest.temperature.toStringAsFixed(1)} °C",
          icon: Icons.thermostat_outlined,
          color: Colors.teal,
        ),
        const SizedBox(height: 10),
        _vitalTile(
          title: "Fall Status",
          value: latest.fallFlag ? "Detected" : "Normal",
          icon: Icons.directions_run_outlined,
          color: latest.fallFlag ? Colors.red : Colors.green,
        ),
        const SizedBox(height: 10),
        _vitalTile(
          title: "Last Update",
          value: _formatDateTime(latest.timestamp),
          icon: Icons.access_time_outlined,
        ),
        const SizedBox(height: 20),
        _sectionTitle("Recent Readings", icon: Icons.history_outlined),
        const SizedBox(height: 10),
        ...history.take(10).map(
          (v) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: PETROL.withOpacity(0.10),
                child: const Icon(Icons.monitor_heart, color: PETROL_DARK),
              ),
              title: Text(
                "HR ${v.hr} • SpO2 ${v.spo2}% • Glucose ${v.glucose.toStringAsFixed(1)}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "BP ${v.sys}/${v.dia} • Temp ${v.temperature.toStringAsFixed(1)}°C\n${_formatDateTime(v.timestamp)}",
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _alertsTab(AppState app) {
    final List<AlertItem> alerts = app.getAlertsForPatient(widget.patient.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("Patient Alerts", icon: Icons.warning_amber_rounded),
        const SizedBox(height: 10),
        if (alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text("لا توجد Alerts لهذا المريض حالياً"),
          )
        else
          ...alerts.map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _severityColor(a.severity).withOpacity(0.12),
                  child: Icon(
                    Icons.notification_important_outlined,
                    color: _severityColor(a.severity),
                  ),
                ),
                title: Text(
                  a.type,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "${a.message}\n${_formatDateTime(a.timestamp)}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _severityColor(a.severity).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    a.severity.toUpperCase(),
                    style: TextStyle(
                      color: _severityColor(a.severity),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                isThreeLine: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _notesTab(AppState app, List<DoctorNote> notes) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("إضافة ملاحظة أو روشتة", icon: Icons.edit_note_rounded),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              TextField(
                controller: _noteCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظاتك التشخيصية أو العلاجية هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showPrescriptionDialog,
                      icon: const Icon(Icons.medical_services_outlined),
                      label: const Text("روشتة رقمية"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PETROL_DARK,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _saveDoctorNote(app),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "حفظ",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle("السجل الطبي والملاحظات", icon: Icons.history_edu),
        const SizedBox(height: 10),
        if (notes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text("لا توجد ملاحظات مسجلة بعد."),
            ),
          )
        else
          ...notes.map(
            (n) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.note_alt_rounded,
                    color: Colors.blueGrey,
                  ),
                ),
                title: Text(
                  n.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDateTime(n.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _reportsTab(AppState app, List<DoctorNote> notes) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("Reports & Actions", icon: Icons.description_outlined),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Patient Report",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Generate and share a PDF report for this patient.",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _exportPdf(app),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    "تصدير تقرير PDF",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Quick Summary",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _reportRow("Patient Name", widget.patient.name),
              _reportRow("Age", "${widget.patient.age}"),
              _reportRow("Gender", _genderText(widget.patient.gender)),
              _reportRow("Blood Type", _textOrNA(widget.patient.bloodType, fallback: "Unknown")),
              _reportRow("Notes Count", "${notes.length}"),
              _reportRow("Generated Date", DateFormat('dd/MM/yyyy').format(DateTime.now())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reportRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final notes = (app.getNotesForPatient(widget.patient.id) ?? [])
        .reversed
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.patient.name),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Medical"),
            Tab(text: "Vitals"),
            Tab(text: "Alerts"),
            Tab(text: "Notes"),
            Tab(text: "Reports"),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: PETROL.withOpacity(0.12),
                  child: const Icon(
                    Icons.person,
                    color: PETROL_DARK,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _textOrNA(widget.patient.email, fallback: "No email"),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _topChip("Age: ${widget.patient.age}"),
                          _topChip("Gender: ${_genderText(widget.patient.gender)}"),
                          _topChip("ID: ${_patientShortId(widget.patient.id)}"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _overviewTab(notes),
                _medicalTab(),
                _vitalsTab(app),
                _alertsTab(app),
                _notesTab(app, notes),
                _reportsTab(app, notes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}