import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentSignUpScreen extends StatefulWidget {
  const ParentSignUpScreen({super.key});

  @override
  State<ParentSignUpScreen> createState() => _ParentSignUpScreenState();
}

class _ParentSignUpScreenState extends State<ParentSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _passwordController = TextEditingController();
  final _address = TextEditingController();
  final _relation = ValueNotifier<String>('Father');

  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _passwordController.dispose();
    _address.dispose();
    _relation.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Parent عندك بيستخدم phone كـ username، خلي email وهمي أو اعملي phone auth (حسب مشروعك)
      final emailAsPhone = "${_phone.text.trim()}@parent.local";

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAsPhone,
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'parent',
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'relation': _relation.value,
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Main.dart يودّي للـHome
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 6) ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: "Address", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<String>(
                valueListenable: _relation,
                builder: (_, v, __) {
                  return DropdownButtonFormField<String>(
                    value: v,
                    decoration: const InputDecoration(labelText: "Relation", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: "Father", child: Text("Father")),
                      DropdownMenuItem(value: "Mother", child: Text("Mother")),
                      DropdownMenuItem(value: "Guardian", child: Text("Guardian")),
                    ],
                    onChanged: (x) => _relation.value = x ?? "Father",
                  );
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Save Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
