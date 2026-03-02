import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/parent.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import 'parent_settings_screen.dart'; // تأكدي من استيراد الصفحة الجديدة

class ParentHomeScreen extends StatefulWidget {
  final Parent parent;
  const ParentHomeScreen({super.key, required this.parent});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // قائمة الصفحات
    final List<Widget> pages = [
      _DashboardTab(parent: widget.parent), // فصلنا الداشبورد في ويدجت لوحدها تحت
      ParentSettingsScreen(parent: widget.parent),
    ];

    return Scaffold(
      // الـ Body بيعرض الصفحة حسب الـ index المختار
      body: pages[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: PETROL,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile & Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------- DASHBOARD TAB ----------------
// دي كانت محتوى الصفحة القديمة، فصلناها هنا للنظام
class _DashboardTab extends StatelessWidget {
  final Parent parent;
  const _DashboardTab({required this.parent});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    
    // فلترة المرضى المرتبطين بهذا الأب
    final childrenPatients = app.patients.values
        .where((p) => p.parentId == parent.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        backgroundColor: PETROL_DARK,
        automaticallyImplyLeading: false, // شيلنا سهم الرجوع
      ),
      body: Column(
        children: [
          // Banner ترحيبي بسيط
          Container(
            padding: const EdgeInsets.all(20),
            color: PETROL.withOpacity(0.05),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: PETROL,
                  child: Icon(Icons.family_restroom, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${parent.name}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text("Monitor your loved ones here."),
                  ],
                )
              ],
            ),
          ),
          
          Expanded(
            child: childrenPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.child_care, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No linked patients yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Go to "Settings" to copy your ID\nand share it with the patient.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: childrenPatients.length,
                    itemBuilder: (context, index) {
                      final p = childrenPatients[index];
                      // جلب آخر قراءة حيوية
                      final vitals = app.getVitalsForPatient(p.id);
                      // ترتيبهم عشان نجيب الأحدث (لو مش مترتبين في AppState)
                      vitals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      final last = vitals.isNotEmpty ? vitals.first : null;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: PETROL.withOpacity(0.1),
                            backgroundImage: p.profilePic != null ? NetworkImage(p.profilePic!) : null,
                            child: p.profilePic == null 
                                ? Text(p.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: PETROL))
                                : null,
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: last == null
                                ? Row(
                                    children: const [
                                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text("No data received yet"),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text("${last.hr} bpm"),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text("${last.spo2}%"),
                                    ],
                                  ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            // هنا ممكن تفتحي صفحة تفاصيل المريض (مثل ChartsScreen)
                            // Navigator.push(...)
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}