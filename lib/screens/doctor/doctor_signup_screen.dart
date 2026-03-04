import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/invite_service.dart';
import '../../utils/doctor_specialties.dart';
import 'doctor_additional_info_screen.dart'; // تأكدي إن الملف ده موجود بنفس الاسم

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final inviteController = TextEditingController();
  final nameController = TextEditingController();

  String? selectedMainSpecialty;
  String? selectedSubSpecialty;

  File? optionalDocImage;
  bool loading = false;

  Future<void> pickOptionalImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => optionalDocImage = File(picked.path));
    }
  }

  Future<void> verifyAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedMainSpecialty == null || selectedSubSpecialty == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("برجاء اختيار التخصص")));
      return;
    }

    final inviteCode = inviteController.text.trim();

    // 🚀 السطر السحري للتطوير: لو الكود admin123 هيدخل على طول
    if (inviteCode == "admin123") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAdditionalInfoScreen(
            name: nameController.text.trim(),
            mainSpecialty: selectedMainSpecialty!,
            subSpecialty: selectedSubSpecialty!,
            docImage: optionalDocImage,
            inviteCode: inviteCode, 
          ),
        ),
      );
      return; // عشان ميكملش ويروح يدور في الفايربيس
    }

    setState(() => loading = true);

    try {
      // التحقق من كود الدعوة في فايربيس لو الكود مش admin123
      final inviteDoc = await InviteService.verifyInviteCode(inviteCode);
      if (inviteDoc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("كود الدعوة غير صحيح أو مستخدم مسبقاً")),
        );
        setState(() => loading = false);
        return;
      }

      // لو الكود سليم، ننتقل لصفحة بيانات العيادة
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorAdditionalInfoScreen(
              name: nameController.text.trim(),
              mainSpecialty: selectedMainSpecialty!,
              subSpecialty: selectedSubSpecialty!,
              docImage: optionalDocImage,
              inviteCode: inviteCode,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialties = DoctorSpecialties.specialties;

    return Scaffold(
      appBar: AppBar(title: const Text("بيانات الطبيب الأساسية")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: inviteController,
                decoration: const InputDecoration(
                  labelText: "Invitation Code (كود الدعوة)",
                  hintText: "مثال: admin123 للتجربة",
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "مطلوب"
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "الاسم بالكامل"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "مطلوب" : null,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "التخصص الرئيسي"),
                value: selectedMainSpecialty,
                items: specialties.keys
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMainSpecialty = value;
                    selectedSubSpecialty = null;
                  });
                },
              ),
              const SizedBox(height: 10),

              if (selectedMainSpecialty != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "التخصص الفرعي"),
                  value: selectedSubSpecialty,
                  items: specialties[selectedMainSpecialty]!
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedSubSpecialty = value),
                ),

              const SizedBox(height: 18),

              const Text(
                "اختياري: رفع صورة تصريح المزاولة",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => pickOptionalImage(ImageSource.gallery),
                      icon: const Icon(Icons.image),
                      label: const Text("المعرض"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => pickOptionalImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("الكاميرا"),
                    ),
                  ),
                ],
              ),
              if (optionalDocImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.file(optionalDocImage!, height: 140),
                ),

              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : verifyAndProceed,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: Text(
                    loading ? "جاري التحقق..." : "التالي: بيانات العيادة", 
                    style: const TextStyle(color: Colors.white, fontSize: 16)
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