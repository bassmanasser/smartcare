import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';

class HospitalProfileScreen extends StatelessWidget {
  const HospitalProfileScreen({super.key});

  Future<Map<String, dynamic>?> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data();
    if (userData == null) return null;

    final institutionId = (userData['institutionId'] ?? '').toString();
    if (institutionId.isEmpty) return userData;

    final institutionDoc = await FirebaseFirestore.instance
        .collection('institutions')
        .doc(institutionId)
        .get();

    return {
      ...userData,
      'institutionDoc': institutionDoc.data(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.translate('institution')),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};
          final institutionDoc =
              (data['institutionDoc'] as Map<String, dynamic>?) ?? {};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoTile(
                label: tr.translate('institution_name'),
                value: (institutionDoc['institutionName'] ??
                        data['institutionName'] ??
                        '')
                    .toString(),
              ),
              _InfoTile(
                label: tr.translate('hospital_id'),
                value: (institutionDoc['hospitalId'] ??
                        data['institutionId'] ??
                        '')
                    .toString(),
              ),
              _InfoTile(
                label: tr.translate('institution_address'),
                value: (institutionDoc['institutionAddress'] ??
                        data['institutionAddress'] ??
                        '')
                    .toString(),
              ),
              _InfoTile(
                label: tr.translate('institution_city'),
                value: (institutionDoc['institutionCity'] ??
                        data['institutionCity'] ??
                        '')
                    .toString(),
              ),
              _InfoTile(
                label: tr.translate('full_name'),
                value: (data['name'] ?? '').toString(),
              ),
              _InfoTile(
                label: tr.translate('email'),
                value: (data['email'] ?? '').toString(),
              ),
              _InfoTile(
                label: tr.translate('phone'),
                value: (data['phone'] ?? '').toString(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PETROL.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PETROL_DARK,
            ),
          ),
        ],
      ),
    );
  }
}