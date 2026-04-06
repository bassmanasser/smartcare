import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';

class PendingApprovalScreen extends StatelessWidget {
  final String role;
  final String status;
  final String institutionName;

  const PendingApprovalScreen({
    super.key,
    required this.role,
    required this.status,
    required this.institutionName,
  });

  String _statusText(BuildContext context) {
    final tr = AppLocalizations.of(context);

    switch (status) {
      case 'approved':
        return tr.translate('approved');
      case 'rejected':
        return tr.translate('rejected');
      default:
        return tr.translate('pending');
    }
  }

  Color _statusColor() {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: Text(tr.translate('registration')),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: _statusColor().withOpacity(0.12),
                  child: Icon(
                    status == 'rejected'
                        ? Icons.close_rounded
                        : Icons.hourglass_top_rounded,
                    color: _statusColor(),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _statusText(context),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: PETROL_DARK,
                  ),
                ),
                const SizedBox(height: 10),
                if (institutionName.isNotEmpty)
                  Text(
                    institutionName,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                const SizedBox(height: 18),
                Text(
                  status == 'rejected'
                      ? 'Your registration request was rejected by the hospital admin.'
                      : 'Your registration request has been submitted successfully and is waiting for hospital admin approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL_DARK,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(tr.translate('logout')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}