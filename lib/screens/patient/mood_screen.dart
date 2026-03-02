import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

class MoodScreen extends StatefulWidget {
  final String patientId;
  const MoodScreen({super.key, required this.patientId});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  // --- المتغيرات (State) ---
  String _selectedMood = 'Happy';
  double _sleepHours = 7.0; 
  String _selectedActivity = 'None'; 
  int _waterCups = 0; 
  final _noteController = TextEditingController();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green},
    {'label': 'Neutral', 'icon': Icons.sentiment_neutral, 'color': Colors.amber},
    {'label': 'Sad', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.blue},
    {'label': 'Angry', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red},
    {'label': 'Tired', 'icon': Icons.bedtime, 'color': Colors.purple},
  ];

  final List<String> _activities = [
    'None', 'Walking', 'Running', 'Gym', 'Yoga', 'Swimming', 'Cycling'
  ];

  // --- دالة الحفظ (تم تعديل المسار) ---
  Future<void> _saveWellnessLog() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // ✅ التعديل هنا: الحفظ داخل الـ User Document مباشرة
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .collection('wellness') // اسم الـ Sub-collection الجديد
          .add({
        'mood': _selectedMood,
        'sleepHours': _sleepHours,
        'activity': _selectedActivity,
        'waterCups': _waterCups,
        'note': _noteController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _noteController.clear();
      setState(() {
        _selectedActivity = 'None';
        _waterCups = 0;
      });
      
      FocusScope.of(context).unfocus(); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wellness log saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final dt = timestamp.toDate();
    return "${dt.day}/${dt.month} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // final lang = AppLocalizations.of(context); // فعلي السطر ده لو عندك ترجمة

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Wellness Tracker"),
        backgroundColor: PETROL_DARK,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- الجزء العلوي: إدخال البيانات ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 1. Mood
                  _buildSectionCard(
                    title: "How do you feel?",
                    icon: Icons.emoji_emotions,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _moods.map((m) {
                        bool isSelected = _selectedMood == m['label'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = m['label']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? m['color'].withOpacity(0.1) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: m['color'], width: 2) : null,
                            ),
                            child: Column(
                              children: [
                                Icon(m['icon'], size: 30, color: isSelected ? m['color'] : Colors.grey.shade400),
                                const SizedBox(height: 4),
                                Text(m['label'], style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? m['color'] : Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 2. Sleep
                  _buildSectionCard(
                    title: "Sleep Duration",
                    icon: Icons.bedtime,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_sleepHours.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: PETROL_DARK)),
                            const Text(" hrs", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Slider(
                          value: _sleepHours,
                          min: 0, max: 12, divisions: 24,
                          label: "$_sleepHours hrs",
                          activeColor: PETROL_DARK,
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (val) => setState(() => _sleepHours = val),
                        ),
                      ],
                    ),
                  ),

                  // 3. Activity & Water
                  Row(
                    children: [
                      Expanded(
                        child: _buildSectionCard(
                          title: "Activity",
                          icon: Icons.directions_run,
                          child: DropdownButtonFormField<String>(
                            value: _activities.contains(_selectedActivity) ? _selectedActivity : _activities[0],
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true, fillColor: Colors.grey.shade50,
                            ),
                            items: _activities.map((act) => DropdownMenuItem(value: act, child: Text(act, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: (val) => setState(() => _selectedActivity = val!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSectionCard(
                          title: "Water",
                          icon: Icons.local_drink,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _waterCups > 0 ? _waterCups-- : null),
                                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: const Icon(Icons.remove, size: 20)),
                              ),
                              const SizedBox(width: 12),
                              Text("$_waterCups", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => setState(() => _waterCups++),
                                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.add, size: 20, color: Colors.blue)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 4. Note & Save
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: "Add a note (optional)...",
                      prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveWellnessLog,
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
                      label: Text(_isSaving ? "Saving..." : "Log My Day", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: PETROL_DARK, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- الجزء السفلي: التاريخ (History) ---
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text("Recent Logs", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: StreamBuilder<QuerySnapshot>(
                    // ✅ التعديل هنا: قراءة البيانات من Sub-collection اليوزر
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.patientId)
                        .collection('wellness')
                        .orderBy('timestamp', descending: true)
                        .limit(20)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No records yet.", style: TextStyle(color: Colors.grey)));

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          final moodColor = _moods.firstWhere((m) => m['label'] == data['mood'], orElse: () => {'color': Colors.grey})['color'] as Color;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              dense: true,
                              leading: Container(width: 5, height: 40, decoration: BoxDecoration(color: moodColor, borderRadius: BorderRadius.circular(5))),
                              title: Row(
                                children: [
                                  Text(data['mood'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  if (data['activity'] != 'None')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(data['activity'], style: const TextStyle(fontSize: 10, color: Colors.orange)),
                                    ),
                                ],
                              ),
                              subtitle: Text("Sleep: ${data['sleepHours']}h • Water: ${data['waterCups']} cups", style: const TextStyle(fontSize: 12)),
                              trailing: Text(_formatTimestamp(data['timestamp']), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: Colors.grey.shade600), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}