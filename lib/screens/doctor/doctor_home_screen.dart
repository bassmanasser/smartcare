import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/doctor.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../auth/welcome_screen.dart';

import 'patient_detail_for_doctor_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_stats_screen.dart';
import 'doctor_requests_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorHomeScreen({super.key, required this.doctor});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _tab = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  DocumentReference<Map<String, dynamic>> get _docRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('doctors')
        .doc(uid)
        .withConverter(
          fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
          toFirestore: (m, _) => m,
        );
  }

  Future<Map<String, dynamic>> _fetchDoctorProfile() async {
    final snap = await _docRef.get();
    return snap.data() ?? {};
  }

  String _resolveDoctorId(Map<String, dynamic> data) {
    final raw = (data['doctorID'] ??
            data['doctorId'] ??
            data['uid'] ??
            widget.doctor.id)
        .toString()
        .trim();

    if (raw.isEmpty) return widget.doctor.id;
    return raw;
  }

  String _shortDoctorId(String id) {
    final clean = id.trim();
    if (clean.isEmpty) return "N/A";
    if (clean.length <= 8) return clean;
    return clean.substring(0, 8);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم النسخ ✅")),
    );
  }

  void _showDoctorIdDialog(String doctorId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Doctor ID"),
        content: SelectableText(doctorId),
        actions: [
          TextButton(
            onPressed: () => _copy(doctorId),
            child: const Text("Copy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showDoctorQrSheet(String doctorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Doctor QR Code",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "شارك الكود أو الـ QR مع المريض لربط الحساب بالدكتور",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: doctorId,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: 14),
              SelectableText(
                doctorId,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PETROL_DARK,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _copy(doctorId),
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  label: const Text(
                    "Copy ID",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditProfileSheet(Map<String, dynamic> currentData) {
    final nameCtrl =
        TextEditingController(text: (currentData['name'] ?? '').toString());
    final mainSpecCtrl = TextEditingController(
      text: (currentData['mainSpecialty'] ?? '').toString(),
    );
    final subSpecCtrl = TextEditingController(
      text: (currentData['subSpecialty'] ?? '').toString(),
    );
    final priceCtrl =
        TextEditingController(text: (currentData['price'] ?? '').toString());
    final addressCtrl =
        TextEditingController(text: (currentData['address'] ?? '').toString());
    final hoursCtrl = TextEditingController(
      text: (currentData['workingHours'] ?? '').toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "تعديل بيانات الدكتور",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _field("الاسم", nameCtrl, icon: Icons.person),
                const SizedBox(height: 10),
                _field("التخصص الرئيسي", mainSpecCtrl, icon: Icons.medical_services),
                const SizedBox(height: 10),
                _field("التخصص الفرعي", subSpecCtrl, icon: Icons.local_hospital),
                const SizedBox(height: 10),
                _field(
                  "سعر الكشف",
                  priceCtrl,
                  icon: Icons.payments,
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field("عنوان العيادة", addressCtrl, icon: Icons.location_on),
                const SizedBox(height: 10),
                _field(
                  "ساعات العمل (مثال: 5 PM - 10 PM)",
                  hoursCtrl,
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 16),
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
                    onPressed: () async {
                      try {
                        await _docRef.set({
                          'name': nameCtrl.text.trim(),
                          'mainSpecialty': mainSpecCtrl.text.trim(),
                          'subSpecialty': subSpecCtrl.text.trim(),
                          'price': priceCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'workingHours': hoursCtrl.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("تم حفظ التعديلات ✅"),
                          ),
                        );
                        setState(() {});
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("خطأ: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "حفظ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _field(
    String label,
    TextEditingController c, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Stream<List<String>> _approvedPatientIdsStream(String doctorLinkId) {
    return FirebaseFirestore.instance
        .collection('care_links')
        .where('linkedUserId', isEqualTo: doctorLinkId)
        .where('linkedUserRole', isEqualTo: 'doctor')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => (d.data()['patientId'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final lang = AppLocalizations.of(context);
    final patientsMap = app.patients ?? {};

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDoctorProfile(),
      builder: (context, profileSnap) {
        if (profileSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profileData = profileSnap.data ?? {};
        final doctorLinkId = _resolveDoctorId(profileData);

        return StreamBuilder<List<String>>(
          stream: _approvedPatientIdsStream(doctorLinkId),
          builder: (context, linksSnap) {
            final approvedIds = linksSnap.data ?? [];

            final myPatients = patientsMap.values.where((p) {
              final pid = (p.id ?? '').toString();
              final legacyDoctorId = (p.doctorId ?? '').toString();
              return approvedIds.contains(pid) ||
                  legacyDoctorId == widget.doctor.id ||
                  legacyDoctorId == doctorLinkId;
            }).toList();

            final pages = <Widget>[
              _DoctorDashboardTab(
                doctorName: widget.doctor.name,
                doctorModel: widget.doctor,
                myPatients: myPatients,
                doctorLinkId: doctorLinkId,
                fetchDoctorProfile: _fetchDoctorProfile,
                resolveDoctorId: _resolveDoctorId,
                shortDoctorId: _shortDoctorId,
                onCopy: _copy,
                onShowId: _showDoctorIdDialog,
                onShowQr: _showDoctorQrSheet,
              ),
              _DoctorPatientsTab(
                myPatients: myPatients,
                doctorLinkId: doctorLinkId,
              ),
              DoctorAppointmentsScreen(myPatients: myPatients),
              _DoctorSettingsTab(
                doctorLinkId: doctorLinkId,
                linkedPatientsCount: myPatients.length,
                fetchDoctorProfile: _fetchDoctorProfile,
                resolveDoctorId: _resolveDoctorId,
                onEdit: _openEditProfileSheet,
                onLogout: _logout,
                onCopy: _copy,
                onShowId: _showDoctorIdDialog,
                onShowQr: _showDoctorQrSheet,
              ),
            ];

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                backgroundColor: PETROL_DARK,
                title: Text("د. ${widget.doctor.name}"),
                centerTitle: false,
                actions: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('care_links')
                        .where('linkedUserId', isEqualTo: doctorLinkId)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snap) {
                      final count = snap.data?.docs.length ?? 0;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            tooltip: lang.translate('requests'),
                            icon: const Icon(Icons.mark_email_unread_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DoctorRequestsScreen(doctorId: doctorLinkId),
                                ),
                              );
                            },
                          ),
                          if (count > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  count > 99 ? '99+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    tooltip: lang.translate('logout'),
                    icon: const Icon(Icons.logout),
                    onPressed: _logout,
                  ),
                ],
              ),
              body: SafeArea(child: pages[_tab]),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _tab,
                onTap: (i) => setState(() => _tab = i),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: PETROL_DARK,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_rounded),
                    label: lang.translate('home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.groups_2_rounded),
                    label: lang.translate('patients'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.event_available_rounded),
                    label: lang.translate('sessions'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_rounded),
                    label: lang.translate('settings'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DoctorDashboardTab extends StatelessWidget {
  final String doctorName;
  final Doctor doctorModel;
  final List<dynamic> myPatients;
  final String doctorLinkId;

  final Future<Map<String, dynamic>> Function() fetchDoctorProfile;
  final String Function(Map<String, dynamic>) resolveDoctorId;
  final String Function(String) shortDoctorId;
  final Future<void> Function(String) onCopy;
  final void Function(String) onShowId;
  final void Function(String) onShowQr;

  const _DoctorDashboardTab({
    required this.doctorName,
    required this.doctorModel,
    required this.myPatients,
    required this.doctorLinkId,
    required this.fetchDoctorProfile,
    required this.resolveDoctorId,
    required this.shortDoctorId,
    required this.onCopy,
    required this.onShowId,
    required this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final patientsToday = myPatients.length;
    final sessionsToday = myPatients.length;

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchDoctorProfile(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        final doctorId = resolveDoctorId(data);
        final mainSpec = (data['mainSpecialty'] ?? '').toString().trim();
        final subSpec = (data['subSpecialty'] ?? '').toString().trim();
        final ver = (data['verificationStatus'] ?? 'pending').toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('care_links')
              .where('linkedUserId', isEqualTo: doctorLinkId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, reqSnap) {
            final pendingRequests = reqSnap.data?.docs.length ?? 0;
            final pendingDocs = reqSnap.data?.docs ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: PETROL.withOpacity(0.12),
                          child: const Icon(
                            Icons.medical_services,
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
                                "د. $doctorName",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if ([mainSpec, subSpec]
                                  .where((e) => e.isNotEmpty)
                                  .isNotEmpty)
                                Text(
                                  [mainSpec, subSpec]
                                      .where((e) => e.isNotEmpty)
                                      .join(" • "),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ver == 'approved'
                                          ? Colors.green.withOpacity(0.12)
                                          : Colors.orange.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      ver == 'approved'
                                          ? lang.translate('verified')
                                          : lang.translate('pending'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: ver == 'approved'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      "ID: ${shortDoctorId(doctorId)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              tooltip: lang.translate('copy'),
                              onPressed: () => onCopy(doctorId),
                              icon: const Icon(Icons.copy_rounded),
                            ),
                            IconButton(
                              tooltip: lang.translate('show_qr'),
                              onPressed: () => onShowQr(doctorId),
                              icon: const Icon(Icons.qr_code_2_rounded),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _statCard(
                        title: lang.translate('patients'),
                        value: "$patientsToday",
                        icon: Icons.groups_2_rounded,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        title: lang.translate('requests'),
                        value: "$pendingRequests",
                        icon: Icons.mark_email_unread_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statCard(
                        title: lang.translate('sessions'),
                        value: "$sessionsToday",
                        icon: Icons.event_available_rounded,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        title: lang.translate('rating'),
                        value: "4.8",
                        icon: Icons.star_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    lang.translate('pending_requests'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (pendingDocs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(lang.translate('no_pending_requests')),
                    )
                  else
                    ...pendingDocs.take(3).map((doc) {
                      final data = doc.data();
                      final patientId =
                          (data['patientId'] ?? '').toString().trim();
                      final label = (data['relationshipLabel'] ?? 'Patient')
                          .toString()
                          .trim();
                      final role = (data['linkedUserRole'] ?? 'doctor')
                          .toString()
                          .trim();
                      final isPrimary = data['isPrimary'] == true;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.12),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              color: Colors.orange,
                            ),
                          ),
                          title: Text(
                            label.isEmpty ? lang.translate('request') : label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Patient ID: $patientId • Role: $role${isPrimary ? ' • Primary' : ''}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DoctorRequestsScreen(doctorId: doctorLinkId),
                              ),
                            );
                          },
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  Text(
                    lang.translate('linked_patients'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  myPatients.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(lang.translate('no_linked_patients')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: myPatients.length > 4 ? 4 : myPatients.length,
                          itemBuilder: (context, index) {
                            final p = myPatients[index];
                            final patientName =
                                (p.name ?? 'Unnamed Patient').toString();

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: PETROL.withOpacity(0.12),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: PETROL_DARK,
                                  ),
                                ),
                                title: Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  lang.translate('tap_to_view_details'),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PatientDetailForDoctorScreen(patient: p),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PETROL_DARK),
            ),
            const SizedBox(width: 10),
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
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _DoctorPatientsTab extends StatefulWidget {
  final List<dynamic> myPatients;
  final String doctorLinkId;

  const _DoctorPatientsTab({
    required this.myPatients,
    required this.doctorLinkId,
  });

  @override
  State<_DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<_DoctorPatientsTab> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    final filtered = widget.myPatients.where((p) {
      final name = (p.name ?? '').toString().toLowerCase();
      return name.contains(q.trim().toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: lang.translate('search_patient'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(lang.translate('no_linked_patients')),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final patientName =
                        (p.name ?? 'Unnamed Patient').toString();

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('care_links')
                          .where('patientId', isEqualTo: p.id)
                          .where('linkedUserId', isEqualTo: widget.doctorLinkId)
                          .where('linkedUserRole', isEqualTo: 'doctor')
                          .where('status', isEqualTo: 'approved')
                          .limit(1)
                          .snapshots(),
                      builder: (context, snap) {
                        final linkData = snap.data?.docs.isNotEmpty == true
                            ? snap.data!.docs.first.data()
                            : null;
                        final isPrimary = linkData?['isPrimary'] == true;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: PETROL.withOpacity(0.12),
                              child: const Icon(
                                Icons.person,
                                color: PETROL_DARK,
                              ),
                            ),
                            title: Text(
                              patientName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  lang.translate('tap_to_view_details'),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPrimary
                                            ? Colors.green.withOpacity(0.12)
                                            : Colors.blue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isPrimary
                                            ? lang.translate('primary_doctor')
                                            : lang.translate('approved'),
                                        style: TextStyle(
                                          color: isPrimary
                                              ? Colors.green
                                              : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientDetailForDoctorScreen(patient: p),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DoctorSettingsTab extends StatelessWidget {
  final String doctorLinkId;
  final int linkedPatientsCount;

  final Future<Map<String, dynamic>> Function() fetchDoctorProfile;
  final String Function(Map<String, dynamic>) resolveDoctorId;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function() onLogout;
  final Future<void> Function(String) onCopy;
  final void Function(String) onShowId;
  final void Function(String) onShowQr;

  const _DoctorSettingsTab({
    required this.doctorLinkId,
    required this.linkedPatientsCount,
    required this.fetchDoctorProfile,
    required this.resolveDoctorId,
    required this.onEdit,
    required this.onLogout,
    required this.onCopy,
    required this.onShowId,
    required this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchDoctorProfile(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        final doctorId = resolveDoctorId(data);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('care_links')
              .where('linkedUserId', isEqualTo: doctorLinkId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, reqSnap) {
            final pendingRequests = reqSnap.data?.docs.length ?? 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                      Text(
                        lang.translate('profile'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _kv("Name", (data['name'] ?? '').toString()),
                      _kv("Main Specialty", (data['mainSpecialty'] ?? '').toString()),
                      _kv("Sub Specialty", (data['subSpecialty'] ?? '').toString()),
                      _kv("Clinic", (data['address'] ?? '').toString()),
                      _kv("Working Hours", (data['workingHours'] ?? '').toString()),
                      _kv("Fee", (data['price'] ?? '').toString()),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PETROL_DARK,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => onEdit(data),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: Text(
                            lang.translate('edit_profile'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

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
                      Text(
                        lang.translate('care_access_management'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        icon: Icons.groups_2_rounded,
                        title: lang.translate('linked_patients'),
                        value: "$linkedPatientsCount",
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.mark_email_unread_outlined,
                        title: lang.translate('pending_requests'),
                        value: "$pendingRequests",
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DoctorRequestsScreen(doctorId: doctorLinkId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.mark_email_unread_outlined),
                          label: Text(lang.translate('open_incoming_requests')),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

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
                      Text(
                        lang.translate('doctor_id'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(doctorId),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onCopy(doctorId),
                              icon: const Icon(Icons.copy_rounded),
                              label: Text(lang.translate('copy')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onShowId(doctorId),
                              icon: const Icon(Icons.badge_rounded),
                              label: Text(lang.translate('show_id')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onShowQr(doctorId),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: Text(lang.translate('show_qr')),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      lang.translate('logout'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    if (v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: PETROL.withOpacity(0.12),
          child: Icon(icon, color: PETROL_DARK, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: PETROL_DARK,
          ),
        ),
      ],
    );
  }
}