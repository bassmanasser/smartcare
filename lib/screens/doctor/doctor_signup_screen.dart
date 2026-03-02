import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/doctor.dart';
import '../../services/storage_service.dart';
import '../../services/invite_service.dart';
import '../../utils/doctor_specialties.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final inviteController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedMainSpecialty;
  String? selectedSubSpecialty;

  File? optionalDocImage;
  String? optionalDocImageUrl;

  bool loading = false;

  Future<void> pickOptionalImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => optionalDocImage = File(picked.path));
    }
  }

  Future<void> registerDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedMainSpecialty == null || selectedSubSpecialty == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Choose specialty")));
      return;
    }

    final inviteCode = inviteController.text.trim();
    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invitation code is required")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 1) verify invite
      final inviteDoc = await InviteService.verifyInviteCode(inviteCode);
      if (inviteDoc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid or used invite code")),
        );
        setState(() => loading = false);
        return;
      }

      final inviteData = inviteDoc.data()!;

      // optional email lock
      final allowedEmail = inviteData["allowedEmail"];
      if (allowedEmail != null &&
          allowedEmail.toString().trim().isNotEmpty &&
          allowedEmail.toString().trim().toLowerCase() !=
              emailController.text.trim().toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invite code not valid for this email")),
        );
        setState(() => loading = false);
        return;
      }

      // 2) create user
      final auth = FirebaseAuth.instance;
      final cred = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final uid = cred.user!.uid;

      // 3) optional upload image
      if (optionalDocImage != null) {
        optionalDocImageUrl =
            await StorageService.uploadDoctorDocImage(optionalDocImage!, uid);
      }

      // 4) autoApprove = true
      final autoApprove = (inviteData["autoApprove"] == true);
      final status = autoApprove ? "approved" : "pending";

      final doctor = Doctor(
        uid: uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        mainSpecialty: selectedMainSpecialty!,
        subSpecialty: selectedSubSpecialty!,
        verificationStatus: status,
        corneaImageUrl: optionalDocImageUrl,
        licenseQrData: inviteCode, // نخزن الكود كمرجع داخلي
      );

      await FirebaseFirestore.instance
          .collection("doctors")
          .doc(uid)
          .set(doctor.toMap());

      // 5) mark invite used
      await InviteService.markInviteUsed(
        inviteDocId: inviteDoc.id,
        usedByUid: uid,
      );

      // optional log
      await FirebaseFirestore.instance
          .collection("doctor_verifications")
          .doc(uid)
          .set({
        "doctorUid": uid,
        "inviteCode": inviteCode,
        "docImageUrl": optionalDocImageUrl,
        "status": status,
        "submittedAt": DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor registered & approved ✅")),
        );
        Navigator.pop(context);
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
      appBar: AppBar(title: const Text("Doctor Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: inviteController,
                decoration: const InputDecoration(
                  labelText: "Invitation Code",
                  hintText: "e.g. 8H2K9QAZ",
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Invitation code required"
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Enter name" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Enter email" : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? "Password must be 6+" : null,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Main Specialty"),
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
                  decoration: const InputDecoration(labelText: "Sub Specialty"),
                  value: selectedSubSpecialty,
                  items: specialties[selectedMainSpecialty]!
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedSubSpecialty = value),
                ),

              const SizedBox(height: 18),

              const Text(
                "Optional: Upload document image",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickOptionalImage(ImageSource.gallery),
                      child: const Text("Gallery"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => pickOptionalImage(ImageSource.camera),
                      child: const Text("Camera"),
                    ),
                  ),
                ],
              ),
              if (optionalDocImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.file(optionalDocImage!, height: 140),
                ),

              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: loading ? null : registerDoctor,
                child: Text(loading ? "Registering..." : "Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}