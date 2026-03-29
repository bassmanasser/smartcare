import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DoctorStatsScreen extends StatelessWidget {
  final double fee;
  final int totalPatients;

  const DoctorStatsScreen({super.key, required this.fee, required this.totalPatients, required List<dynamic> myPatients});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الإحصائيات والأداء"), backgroundColor: PETROL_DARK),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatTile("إجمالي الدخل", "${totalPatients * fee} ج.م", Icons.monetization_on, Colors.green),
            const SizedBox(height: 15),
            _buildStatTile("عدد الحالات الكلي", "$totalPatients مريض", Icons.person, Colors.blue),
            const SizedBox(height: 15),
            _buildStatTile("متوسط التقييم", "4.8 / 5", Icons.star, Colors.orange),
            const Divider(height: 40),
            const Text("النمو الأسبوعي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // مكان للـ Chart مستقبلاً
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.bar_chart, size: 100, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}