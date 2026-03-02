import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/doctor.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';
import 'patient_detail_for_doctor_screen.dart';
import 'doctor_stats_screen.dart'; // تأكدي من إنشاء هذا الملف
import 'doctor_appointments_screen.dart'; // تأكدي من إنشاء هذا الملف

class DoctorHomeScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorHomeScreen({super.key, required this.doctor});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    
    // جلب قائمة المرضى المرتبطين بهذا الدكتور
    final patientsMap = app.patients ?? {};
    final myPatients = patientsMap.values
        .where((p) => p.doctorId == doctor.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // خلفية فاتحة لإبراز الـ Cards
      appBar: AppBar(
        elevation: 0,
        backgroundColor: PETROL_DARK,
        title: const Text('لوحة تحكم الطبيب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. الهيدر الشخصي للطبيب ---
            _buildHeader(doctor),

            const SizedBox(height: 20),

            // --- 2. شبكة الخدمات (Grid Services) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "الخدمات السريعة",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PETROL_DARK),
              ),
            ),
            const SizedBox(height: 12),
            _buildServicesGrid(context, myPatients.length, myPatients),

            const SizedBox(height: 24),

            // --- 3. قائمة الحجوزات اليومية ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "حجوزات اليوم",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PETROL_DARK),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen(myPatients: myPatients)),
                      );
                    },
                    child: const Text("عرض الكل"),
                  )
                ],
              ),
            ),
            _buildUpcomingAppointments(myPatients),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ميثود بناء الهيدر
  Widget _buildHeader(Doctor doctor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: PETROL_DARK,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 45, color: PETROL_DARK),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "د. ${doctor.name}",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  doctor.specialty ?? 'Specialty',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "ID: ${doctor.id.substring(0, 8)}",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ميثود بناء شبكة الخدمات
  Widget _buildServicesGrid(BuildContext context, int patientsCount, List myPatients) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _serviceCard("المرضى", Icons.people_alt_rounded, Colors.blue, "$patientsCount مريض", () {
           // يمكن توجيهه لصفحة قائمة المرضى فقط
        }),
        _serviceCard("المواعيد", Icons.event_note_rounded, Colors.orange, "جدول العمل", () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen(myPatients: myPatients)));
        }),
        _serviceCard("الإحصائيات", Icons.insights_rounded, Colors.green, "الأداء المالي", () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorStatsScreen(fee: doctor.consultationFee, totalPatients: patientsCount)));
        }),
        _serviceCard("الأمان", Icons.security_rounded, Colors.redAccent, "سجل الدخول", () {
          // هنا يمكن إضافة جزء الـ Security Log لاحقاً
        }),
      ],
    );
  }

  Widget _serviceCard(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ميثود بناء قائمة الحجوزات القادمة
  Widget _buildUpcomingAppointments(List myPatients) {
    if (myPatients.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text("لا توجد حجوزات مسجلة حالياً")),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: myPatients.length > 3 ? 3 : myPatients.length, // عرض أول 3 فقط في الهوم
      itemBuilder: (context, index) {
        final p = myPatients[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: PETROL.withOpacity(0.1),
              child: const Icon(Icons.access_time_filled, color: PETROL, size: 20),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("اليوم - ${index + 9}:00 AM", style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => PatientDetailForDoctorScreen(patient: p))
            ),
          ),
        );
      },
    );
  }
}

extension on Object {
  substring(int i, int j) {}
}