import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/doctor.dart';
import '../../utils/constants.dart';
import 'booking_screen.dart'; // تأكدي من وجود الملف

class PatientDoctorSearchScreen extends StatefulWidget {
  const PatientDoctorSearchScreen({super.key});

  @override
  State<PatientDoctorSearchScreen> createState() => _PatientDoctorSearchScreenState();
}

class _PatientDoctorSearchScreenState extends State<PatientDoctorSearchScreen> {
  String? _selectedCategory;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    // تصفية الدكاترة بناءً على التخصص والبحث
    final allDoctors = app.doctors.values.toList() ?? [];
    final filteredDoctors = allDoctors.where((doc) {
      bool matchesCat = _selectedCategory == null || doc.specialty.contains(_selectedCategory!);
      bool matchesSearch = doc.name.contains(_searchQuery);
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("البحث عن طبيب"), backgroundColor: PETROL_DARK),
      body: Column(
        children: [
          // شريط البحث والفلترة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "بحث باسم الدكتور...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["باطنة", "جراحة", "أطفال", "قلب"].map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) => setState(() => _selectedCategory = selected ? cat : null),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) {
                final doc = filteredDoctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: const CircleAvatar(radius: 30, backgroundColor: PETROL, child: Icon(Icons.person, color: Colors.white)),
                    title: Text("د. ${doc.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.specialty),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), Text(doc.clinicAddress, style: const TextStyle(fontSize: 12))]),
                        const SizedBox(height: 4),
                        Text("${doc.consultationFee} ج.م", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: PETROL),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(doctor: doc))),
                      child: const Text("حجز", style: TextStyle(color: Colors.white)),
                    ),
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

extension on List<Map<String, dynamic>> {
  get values => null;
}