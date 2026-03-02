import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/doctor.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';
import 'patient_detail_for_doctor_screen.dart';
import 'doctor_stats_screen.dart'; 
import 'doctor_appointments_screen.dart'; 

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
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: Text("مرحباً د. ${doctor.name}"),
        backgroundColor: PETROL_DARK,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم الأزرار السريعة (الإحصائيات والمواعيد)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorStatsScreen(fee: doctor.consultationFee, totalPatients: myPatients.length))),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(15)),
                        child: const Column(
                          children: [
                            Icon(Icons.bar_chart, color: Colors.white, size: 40),
                            SizedBox(height: 10),
                            Text("الإحصائيات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen(myPatients: myPatients))),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(15)),
                        child: const Column(
                          children: [
                            Icon(Icons.calendar_month, color: Colors.white, size: 40),
                            SizedBox(height: 10),
                            Text("جدول المواعيد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text("أحدث الحجوزات اليوم", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            // عرض الحجوزات
            myPatients.isEmpty
              ? Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text("لا توجد حجوزات مسجلة حالياً")),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myPatients.length > 3 ? 3 : myPatients.length, 
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
                ),
          ],
        ),
      ),
    );
  }
}