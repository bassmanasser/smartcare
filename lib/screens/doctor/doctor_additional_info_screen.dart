import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';

class DoctorAdditionalInfoScreen extends StatefulWidget {
  final String name;
  final String mainSpecialty;
  final String subSpecialty;
  final File? docImage;
  final String inviteCode;

  const DoctorAdditionalInfoScreen({
    super.key,
    required this.name,
    required this.mainSpecialty,
    required this.subSpecialty,
    this.docImage,
    required this.inviteCode,
  });

  @override
  State<DoctorAdditionalInfoScreen> createState() => _DoctorAdditionalInfoScreenState();
}

class _DoctorAdditionalInfoScreenState extends State<DoctorAdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final priceController = TextEditingController();
  final addressController = TextEditingController();
  
  // أيام العمل
  List<String> days = ["السبت", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"];
  List<String> selectedDays = [];

  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool loading = false;

  // توليد كود ربط عشوائي للطبيب (Doctor ID)
  String generateDoctorID() {
    return "DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
  }

  Future<void> saveDoctorData() async {
    if (!_formKey.currentState!.validate() || selectedDays.isEmpty || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("برجاء إكمال جميع البيانات واختيار المواعيد")));
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl;
      if (widget.docImage != null) {
        imageUrl = await StorageService.uploadDoctorDocImage(widget.docImage!, user.uid);
      }

      String doctorID = generateDoctorID();

      // تجهيز بيانات الدكتور
      final doctorData = {
        "uid": user.uid,
        "doctorID": doctorID, // كود الربط اللي هيظهر في السيتنج
        "name": widget.name,
        "email": user.email,
        "mainSpecialty": widget.mainSpecialty,
        "subSpecialty": widget.subSpecialty,
        "price": priceController.text.trim(),
        "address": addressController.text.trim(),
        "workingDays": selectedDays,
        "workingHours": "${startTime!.format(context)} - ${endTime!.format(context)}",
        "verificationStatus": "approved",
        "docImageUrl": imageUrl,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection("doctors").doc(user.uid).set(doctorData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تسجيل البيانات بنجاح ✅")));
        // التوجه لصفحة الهوم الخاصة بالدكتور
        // عدلي الـ Route حسب اسم صفحة الهوم عندك في الـ main.dart
        Navigator.pushNamedAndRemoveUntil(context, '/doctorHome', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بيانات العيادة والمواعيد")),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("بيانات العيادة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: "سعر الكشف (ج.م)", prefixIcon: Icon(Icons.money)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "مطلوب" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "عنوان العيادة بالتفصيل", prefixIcon: Icon(Icons.location_on)),
                    validator: (v) => v!.isEmpty ? "مطلوب" : null,
                  ),
                  const SizedBox(height: 25),
                  const Text("أيام العمل", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: days.map((day) {
                      final isSelected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            val ? selectedDays.add(day) : selectedDays.remove(day);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text("ساعات العمل", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (picked != null) setState(() => startTime = picked);
                          },
                          child: Text(startTime == null ? "من" : startTime!.format(context)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (picked != null) setState(() => endTime = picked);
                          },
                          child: Text(endTime == null ? "إلى" : endTime!.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: saveDoctorData,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text("إتمام التسجيل", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}