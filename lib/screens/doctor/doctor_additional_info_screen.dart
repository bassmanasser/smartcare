import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare/utils/constants.dart';

import '../../models/doctor.dart';
import '../../services/storage_service.dart';
import '../../screens/doctor/doctor_home_screen.dart';

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
  State<DoctorAdditionalInfoScreen> createState() =>
      _DoctorAdditionalInfoScreenState();
}

class _DoctorAdditionalInfoScreenState
    extends State<DoctorAdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // القديم
  final priceController = TextEditingController();
  final addressController = TextEditingController();

  // الجديد - Institution based
  final institutionNameController = TextEditingController();
  final institutionCodeController = TextEditingController();
  final departmentController = TextEditingController();
  final employeeIdController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final workPhoneController = TextEditingController();

  String selectedStaffRole = 'doctor';
  String selectedMedicalRole = 'Attending Physician';

  final List<String> days = const [
    "السبت",
    "الأحد",
    "الإثنين",
    "الثلاثاء",
    "الأربعاء",
    "الخميس",
    "الجمعة",
  ];

  List<String> selectedDays = [];
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool loading = false;

  @override
  void dispose() {
    priceController.dispose();
    addressController.dispose();

    institutionNameController.dispose();
    institutionCodeController.dispose();
    departmentController.dispose();
    employeeIdController.dispose();
    licenseNumberController.dispose();
    workPhoneController.dispose();

    super.dispose();
  }

  String generateDoctorID() {
    return "DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
  }

  String _workingHoursText() {
    return "${startTime!.format(context)} - ${endTime!.format(context)}";
  }

  String _normalizedInstitutionId() {
    final raw = institutionCodeController.text.trim().isNotEmpty
        ? institutionCodeController.text.trim()
        : institutionNameController.text.trim();

    return raw
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _normalizedDepartmentId() {
    return departmentController.text
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> saveDoctorData() async {
    if (!_formKey.currentState!.validate() ||
        selectedDays.isEmpty ||
        startTime == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("برجاء إكمال جميع البيانات واختيار المواعيد"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("لا يوجد مستخدم مسجل دخول حاليًا");
      }

      await user.reload();
      final freshUser = FirebaseAuth.instance.currentUser;

      if (freshUser == null) {
        throw Exception("فشل التحقق من جلسة تسجيل الدخول");
      }

      String? imageUrl;
      if (widget.docImage != null) {
        imageUrl = await StorageService.uploadDoctorDocImage(
          widget.docImage!,
          freshUser.uid,
        );
      }

      final doctorID = generateDoctorID();
      final workingHours = _workingHoursText();

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection("users").doc(freshUser.uid);
      final doctorRef = firestore.collection("doctors").doc(freshUser.uid);
      final staffRequestRef =
          firestore.collection("staff_requests").doc(freshUser.uid);

      final institutionId = _normalizedInstitutionId();
      final departmentId = _normalizedDepartmentId();

      final institutionRef =
          firestore.collection("institutions").doc(institutionId);
      final departmentRef = firestore
          .collection("departments")
          .doc("${institutionId}_$departmentId");

      final userData = {
        // القديم
        "uid": freshUser.uid,
        "role": "doctor",
        "name": widget.name,
        "phone": freshUser.phoneNumber,
        "email": freshUser.email,
        "doctorID": doctorID,
        "mainSpecialty": widget.mainSpecialty,
        "subSpecialty": widget.subSpecialty,
        "profileCompleted": true,
        "updatedAt": FieldValue.serverTimestamp(),

        // الجديد
        "staffRole": selectedStaffRole,
        "medicalRole": selectedMedicalRole,
        "institutionId": institutionId,
        "institutionName": institutionNameController.text.trim(),
        "institutionCode": institutionCodeController.text.trim(),
        "departmentId": departmentId,
        "departmentName": departmentController.text.trim(),
        "employeeId": employeeIdController.text.trim(),
        "licenseNumber": licenseNumberController.text.trim(),
        "workPhone": workPhoneController.text.trim(),
        "approvalStatus": "pending",
        "availabilityStatus": "available",
        "workflowType": "institution_staff_member",
      };

      final doctorData = {
        // القديم
        "uid": freshUser.uid,
        "doctorID": doctorID,
        "name": widget.name,
        "email": freshUser.email,
        "mainSpecialty": widget.mainSpecialty,
        "subSpecialty": widget.subSpecialty,
        "price": priceController.text.trim(),
        "address": addressController.text.trim(),
        "workingDays": selectedDays,
        "workingHours": workingHours,
        "verificationStatus": "approved",
        "docImageUrl": imageUrl,
        "inviteCode": widget.inviteCode,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),

        // الجديد
        "staffRole": selectedStaffRole,
        "medicalRole": selectedMedicalRole,
        "institutionId": institutionId,
        "institutionName": institutionNameController.text.trim(),
        "institutionCode": institutionCodeController.text.trim(),
        "departmentId": departmentId,
        "departmentName": departmentController.text.trim(),
        "employeeId": employeeIdController.text.trim(),
        "licenseNumber": licenseNumberController.text.trim(),
        "workPhone": workPhoneController.text.trim(),
        "approvalStatus": "pending",
        "availabilityStatus": "available",
      };

      final staffRequestData = {
        "uid": freshUser.uid,
        "doctorID": doctorID,
        "name": widget.name,
        "email": freshUser.email,
        "phone": freshUser.phoneNumber,
        "mainSpecialty": widget.mainSpecialty,
        "subSpecialty": widget.subSpecialty,
        "staffRole": selectedStaffRole,
        "medicalRole": selectedMedicalRole,
        "institutionId": institutionId,
        "institutionName": institutionNameController.text.trim(),
        "institutionCode": institutionCodeController.text.trim(),
        "departmentId": departmentId,
        "departmentName": departmentController.text.trim(),
        "employeeId": employeeIdController.text.trim(),
        "licenseNumber": licenseNumberController.text.trim(),
        "workPhone": workPhoneController.text.trim(),
        "price": priceController.text.trim(),
        "address": addressController.text.trim(),
        "workingDays": selectedDays,
        "workingHours": workingHours,
        "docImageUrl": imageUrl,
        "inviteCode": widget.inviteCode,
        "approvalStatus": "pending",
        "availabilityStatus": "available",
        "submittedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      final institutionData = {
        "id": institutionId,
        "name": institutionNameController.text.trim(),
        "code": institutionCodeController.text.trim(),
        "type": "Hospital",
        "address": addressController.text.trim(),
        "phone": workPhoneController.text.trim(),
        "email": freshUser.email,
        "departments": FieldValue.arrayUnion([departmentController.text.trim()]),
        "status": "active",
        "updatedAt": FieldValue.serverTimestamp(),
      };

      final departmentData = {
        "id": departmentId,
        "institutionId": institutionId,
        "name": departmentController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();
      batch.set(userRef, userData, SetOptions(merge: true));
      batch.set(doctorRef, doctorData, SetOptions(merge: true));
      batch.set(staffRequestRef, staffRequestData, SetOptions(merge: true));
      batch.set(institutionRef, institutionData, SetOptions(merge: true));
      batch.set(departmentRef, departmentData, SetOptions(merge: true));
      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم تسجيل البيانات وإرسال طلب الانضمام للمؤسسة ✅"),
        ),
      );

      final newDoctor = Doctor(
        uid: freshUser.uid,
        institutionId: institutionId,
        institutionName: institutionNameController.text.trim(),
        institutionCode: institutionCodeController.text.trim(),
        departmentId: departmentId,
        departmentName: departmentController.text.trim(),
        staffRole: selectedStaffRole,
        medicalRole: selectedMedicalRole,
        employeeId: employeeIdController.text.trim(),
        licenseNumber: licenseNumberController.text.trim(),
        workPhone: workPhoneController.text.trim(),
        approvalStatus: "pending",
        availabilityStatus: "available",
        name: widget.name,
        email: freshUser.email ?? "",
        mainSpecialty: widget.mainSpecialty,
        subSpecialty: widget.subSpecialty, verificationStatus: '', corneaImageUrl: null,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorHomeScreen(doctor: newDoctor),
        ),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      String msg = e.message ?? e.code;

      if (e.code == 'permission-denied') {
        msg =
            "تم رفض الصلاحية من Firestore. تأكدي أن إنشاء حساب الدكتور تم قبل الحفظ، وأن المستند يُكتب بالـ uid نفسه.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $msg")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        title: const Text(
          "بيانات العيادة والمواعيد",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [PETROL_DARK, PETROL],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.local_hospital_rounded,
                              color: PETROL_DARK,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${widget.mainSpecialty} • ${widget.subSpecialty}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "بيانات المؤسسة الطبية",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: institutionNameController,
                      decoration: _inputDecoration(
                        "اسم المستشفى / المؤسسة",
                        Icons.local_hospital,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: institutionCodeController,
                      decoration: _inputDecoration(
                        "Institution Code / Hospital Code",
                        Icons.qr_code_2,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: departmentController,
                      decoration: _inputDecoration(
                        "القسم / Department",
                        Icons.apartment,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedStaffRole,
                      decoration: _inputDecoration(
                        "الدور داخل النظام",
                        Icons.badge,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'doctor',
                          child: Text('Doctor'),
                        ),
                        DropdownMenuItem(
                          value: 'nurse',
                          child: Text('Nurse'),
                        ),
                        DropdownMenuItem(
                          value: 'triage_staff',
                          child: Text('Triage Staff'),
                        ),
                        DropdownMenuItem(
                          value: 'hospital_admin',
                          child: Text('Hospital Admin'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          selectedStaffRole = v ?? 'doctor';
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedMedicalRole,
                      decoration: _inputDecoration(
                        "Medical Role",
                        Icons.medical_services,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Attending Physician',
                          child: Text('Attending Physician'),
                        ),
                        DropdownMenuItem(
                          value: 'Resident Doctor',
                          child: Text('Resident Doctor'),
                        ),
                        DropdownMenuItem(
                          value: 'Consultant',
                          child: Text('Consultant'),
                        ),
                        DropdownMenuItem(
                          value: 'Nurse',
                          child: Text('Nurse'),
                        ),
                        DropdownMenuItem(
                          value: 'Triage Officer',
                          child: Text('Triage Officer'),
                        ),
                        DropdownMenuItem(
                          value: 'Hospital Admin',
                          child: Text('Hospital Admin'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          selectedMedicalRole = v ?? 'Attending Physician';
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: employeeIdController,
                      decoration: _inputDecoration(
                        "Employee ID",
                        Icons.confirmation_number,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: licenseNumberController,
                      decoration: _inputDecoration(
                        "License Number",
                        Icons.verified_user,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: workPhoneController,
                      decoration: _inputDecoration(
                        "Work Phone",
                        Icons.phone,
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      "بيانات العيادة",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: priceController,
                      decoration:
                          _inputDecoration("سعر الكشف (ج.م)", Icons.money),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: addressController,
                      decoration: _inputDecoration(
                        "عنوان العيادة بالتفصيل",
                        Icons.location_on,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      "أيام العمل",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: days.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                if (!selectedDays.contains(day)) {
                                  selectedDays.add(day);
                                }
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "ساعات العمل",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() => startTime = picked);
                              }
                            },
                            child: Text(
                              startTime == null
                                  ? "من"
                                  : startTime!.format(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() => endTime = picked);
                              }
                            },
                            child: Text(
                              endTime == null
                                  ? "إلى"
                                  : endTime!.format(context),
                            ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PETROL_DARK,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "إتمام التسجيل",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}