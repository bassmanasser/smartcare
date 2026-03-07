import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import 'linked_accounts_screen.dart';

class PatientSettingsScreen extends StatelessWidget {
  final String patientId;
  final Future<void> Function() onLogout;

  const PatientSettingsScreen({
    super.key,
    required this.patientId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: PETROL_DARK,
            centerTitle: true,
            automaticallyImplyLeading: false,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Account'),

              _SettingsTile(
                icon: Icons.people_alt_rounded,
                iconColor: Colors.indigo,
                title: 'Linked Doctors & Family',
                subtitle: 'Manage requests, permissions and relationships',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LinkedAccountsScreen(patientId: patientId),
                    ),
                  );
                },
              ),

              _SettingsTile(
                icon: Icons.person_search_rounded,
                iconColor: Colors.blue,
                title: 'Care Team Management',
                subtitle: 'Invite doctors and family members securely',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LinkedAccountsScreen(patientId: patientId),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),
              _buildSectionTitle('Device'),

              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: app.isDeviceConnected
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                      child: Icon(
                        app.isDeviceConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color:
                            app.isDeviceConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app.isDeviceConnected
                                ? 'Connected and monitoring is active'
                                : 'Disconnected',
                            style: TextStyle(
                              color: app.isDeviceConnected
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bluetooth_connected),
                      label: const Text('Connect'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await app.connectDevice(patientId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Connecting device...')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                      label: const Text(
                        'Disconnect',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await app.disconnectDevice();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Device disconnected')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              _buildSectionTitle('App'),

              _SettingsTile(
                icon: Icons.language_rounded,
                iconColor: Colors.teal,
                title: 'Language',
                subtitle: 'Arabic / English',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Language'),
                      content: const Text(
                        'لو عندك change language function جاهزة في AppState أو localization، وصّليها هنا.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              _SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: Colors.orange,
                title: 'About',
                subtitle: 'SmartCare patient settings and linked accounts',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'SmartCare',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Patient monitoring application',
                  );
                },
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PETROL_DARK,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (ok == true) {
                      await onLogout();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: PETROL_DARK,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}