import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/doctor.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';

import 'patient_detail_for_doctor_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_stats_screen.dart';

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

  // ---- Firestore helpers ----
  DocumentReference<Map<String, dynamic>> get _docRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // عندكم في التسجيل بتعملوا doctors/{uid}
    return FirebaseFirestore.instance.collection('doctors').doc(uid).withConverter(
      fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
      toFirestore: (m, _) => m,
    );
  }

  Future<Map<String, dynamic>> _fetchDoctorProfile() async {
    final snap = await _docRef.get();
    return snap.data() ?? {};
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

  void _openEditProfileSheet(Map<String, dynamic> currentData) {
    final nameCtrl = TextEditingController(text: (currentData['name'] ?? '').toString());
    final mainSpecCtrl = TextEditingController(text: (currentData['mainSpecialty'] ?? '').toString());
    final subSpecCtrl = TextEditingController(text: (currentData['subSpecialty'] ?? '').toString());
    final priceCtrl = TextEditingController(text: (currentData['price'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (currentData['address'] ?? '').toString());
    final hoursCtrl = TextEditingController(text: (currentData['workingHours'] ?? '').toString());

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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                _field("سعر الكشف", priceCtrl, icon: Icons.payments, keyboard: TextInputType.number),
                const SizedBox(height: 10),
                _field("عنوان العيادة", addressCtrl, icon: Icons.location_on),
                const SizedBox(height: 10),
                _field("ساعات العمل (مثال: 5 PM - 10 PM)", hoursCtrl, icon: Icons.schedule),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL_DARK,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                          const SnackBar(content: Text("تم حفظ التعديلات ✅")),
                        );
                        setState(() {}); // refresh
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("خطأ: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text("حفظ", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- UI helpers ----------
  Widget _field(String label, TextEditingController c,
      {IconData? icon, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _pill({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PETROL.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PETROL_DARK),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required String title, required String value, required IconData icon}) {
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
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    // مرضى الدكتور (زي ما كان عندك)
    final patientsMap = app.patients ?? {};
    final myPatients = patientsMap.values.where((p) => p.doctorId == widget.doctor.id).toList();

    final pages = <Widget>[
      _DoctorDashboardTab(
        doctorName: widget.doctor.name,
        doctorModel: widget.doctor,
        myPatients: myPatients,
        fetchDoctorProfile: _fetchDoctorProfile,
        onCopy: _copy,
        onShowId: _showDoctorIdDialog,
      ),
      _DoctorPatientsTab(myPatients: myPatients),
      DoctorAppointmentsScreen(myPatients: myPatients),
      _DoctorSettingsTab(
        fetchDoctorProfile: _fetchDoctorProfile,
        onEdit: _openEditProfileSheet,
        onLogout: _logout,
        onCopy: _copy,
        onShowId: _showDoctorIdDialog,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        title: Text("د. ${widget.doctor.name}"),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: "Logout",
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.groups_2_rounded), label: "Patients"),
          BottomNavigationBarItem(icon: Icon(Icons.event_available_rounded), label: "Sessions"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
        ],
      ),
    );
  }
}

// =====================
// TAB 1: Dashboard (Home)
// =====================
class _DoctorDashboardTab extends StatelessWidget {
  final String doctorName;
  final Doctor doctorModel;
  final List myPatients;

  final Future<Map<String, dynamic>> Function() fetchDoctorProfile;
  final Future<void> Function(String) onCopy;
  final void Function(String) onShowId;

  const _DoctorDashboardTab({
    required this.doctorName,
    required this.doctorModel,
    required this.myPatients,
    required this.fetchDoctorProfile,
    required this.onCopy,
    required this.onShowId,
  });

  @override
  Widget build(BuildContext context) {
    final patientsToday = myPatients.length; // placeholder “Today”
    final alertsToday = 0; // لو عندكم alerts هنوصلها بعدين
    final sessionsToday = myPatients.length; // placeholder

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchDoctorProfile(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        final doctorId = (data['doctorID'] ?? data['doctorId'] ?? data['uid'] ?? 'N/A').toString();
        final mainSpec = (data['mainSpecialty'] ?? '').toString();
        final subSpec = (data['subSpecialty'] ?? '').toString();
        final ver = (data['verificationStatus'] ?? 'pending').toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Profile Header Card + 2) Doctor ID Copy + 3) “QR optional”
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: PETROL.withOpacity(0.12),
                      child: const Icon(Icons.medical_services, color: PETROL_DARK, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("د. $doctorName",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(
                            [mainSpec, subSpec].where((e) => e.trim().isNotEmpty).join(" • "),
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ver == 'approved'
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  ver == 'approved' ? "Verified" : "Pending",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: ver == 'approved' ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => onShowId(doctorId),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.qr_code_2, size: 16),
                                      SizedBox(width: 6),
                                      Text("Doctor ID", style: TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Copy ID",
                      onPressed: () => onCopy(doctorId),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Optional QR (لو عايزة الحقيقي: add qr_flutter)
              // Container(
              //   margin: const EdgeInsets.only(top: 10),
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(color: Colors.grey.shade200),
              //   ),
              //   child: QrImageView(data: doctorId, size: 120),
              // ),

              // 4) Today Overview
              Row(
                children: [
                  _statCard(title: "Patients", value: "$patientsToday", icon: Icons.groups_2_rounded),
                  const SizedBox(width: 10),
                  _statCard(title: "Alerts", value: "$alertsToday", icon: Icons.notifications_active_rounded),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard(title: "Sessions", value: "$sessionsToday", icon: Icons.event_available_rounded),
                  const SizedBox(width: 10),
                  _statCard(title: "Rating", value: "4.8", icon: Icons.star_rounded),
                ],
              ),

              const SizedBox(height: 16),

              // 5) Quick Actions (Stats / Sessions / Patients / ID)
              Text("Quick Actions", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _pill(
                icon: Icons.bar_chart_rounded,
                title: "الإحصائيات",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorStatsScreen(
                        fee: doctorModel.consultationFee,
                        totalPatients: myPatients.length,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _pill(
                icon: Icons.event_available_rounded,
                title: "Sessions / Appointments",
                onTap: () {
                  DefaultTabController.of(context); // no-op
                  // هنروح مباشرة للتاب 3 لو عايزة (بس هنا داخل تبويب Home)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen(myPatients: myPatients)),
                  );
                },
              ),
              const SizedBox(height: 10),
              _pill(
                icon: Icons.groups_2_rounded,
                title: "My Patients",
                onTap: () {
                  // نفتح قائمة المرضى كاملة
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _DoctorPatientsTab(myPatients: myPatients)),
                  );
                },
              ),
              const SizedBox(height: 10),
              _pill(
                icon: Icons.badge_rounded,
                title: "Show Doctor ID",
                onTap: () => onShowId(doctorId),
              ),

              const SizedBox(height: 18),

              // 6) Recent Activity / 7) Recent Bookings
              const Text("أحدث الحجوزات اليوم", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: const Text("لا توجد حجوزات مسجلة حالياً"),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myPatients.length > 4 ? 4 : myPatients.length,
                      itemBuilder: (context, index) {
                        final p = myPatients[index];
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
                              child: const Icon(Icons.access_time_filled, color: PETROL_DARK, size: 18),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("اليوم - ${index + 9}:00 AM",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PatientDetailForDoctorScreen(patient: p)),
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
  }

  Widget _pill({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PETROL.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PETROL_DARK),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required String title, required String value, required IconData icon}) {
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
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// =====================
// TAB 2: Patients
// =====================
class _DoctorPatientsTab extends StatefulWidget {
  final List myPatients;
  const _DoctorPatientsTab({required this.myPatients});

  @override
  State<_DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<_DoctorPatientsTab> {
  String q = '';

  @override
  Widget build(BuildContext context) {
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
              hintText: "ابحث عن مريض...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("لا يوجد مرضى مرتبطين حالياً"))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
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
                          child: const Icon(Icons.person, color: PETROL_DARK),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("اضغط لعرض التفاصيل", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PatientDetailForDoctorScreen(patient: p)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// =====================
// TAB 4: Settings
// =====================
class _DoctorSettingsTab extends StatelessWidget {
  final Future<Map<String, dynamic>> Function() fetchDoctorProfile;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function() onLogout;
  final Future<void> Function(String) onCopy;
  final void Function(String) onShowId;

  const _DoctorSettingsTab({
    required this.fetchDoctorProfile,
    required this.onEdit,
    required this.onLogout,
    required this.onCopy,
    required this.onShowId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchDoctorProfile(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        final doctorId = (data['doctorID'] ?? data['doctorId'] ?? data['uid'] ?? 'N/A').toString();

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
                  const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => onEdit(data),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
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
                  const Text("Doctor ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  SelectableText(doctorId),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onCopy(doctorId),
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text("Copy"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onShowId(doctorId),
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text("Show"),
                        ),
                      ),
                    ],
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
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
          SizedBox(width: 120, child: Text(k, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}