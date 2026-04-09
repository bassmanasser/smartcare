import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import 'patient_qr_simple_screen.dart';

class PatientSettingsScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final Future<void> Function() onLogout;

  const PatientSettingsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Consumer<AppState>(
      builder: (context, app, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(lang.translate('settings')),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(lang.translate('account')),
              _SettingsTile(
                icon: Icons.qr_code_rounded,
                iconColor: Colors.teal,
                title: lang.translate('my_qr_code'),
                subtitle: lang.translate('show_qr_for_doctor_scan'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientQrSimpleScreen(
                        patientId: patientId,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _buildSectionTitle(lang.translate('device')),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 10),
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
                        color: app.isDeviceConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate('device_status'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app.isDeviceConnected
                                ? lang.translate('connected_monitoring_active')
                                : lang.translate('disconnected'),
                            style: TextStyle(
                              color: app.isDeviceConnected ? Colors.green : Colors.red,
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
                      label: Text(lang.translate('connect')),
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
                            SnackBar(
                              content: Text(lang.translate('connecting_device')),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                      label: Text(
                        lang.translate('disconnect'),
                        style: const TextStyle(color: Colors.white),
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
                            SnackBar(
                              content: Text(lang.translate('device_disconnected')),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionTitle(lang.translate('app')),
              _SettingsTile(
                icon: Icons.language_rounded,
                iconColor: Colors.teal,
                title: lang.translate('language'),
                subtitle: app.currentLocale.languageCode == 'ar'
                    ? 'العربية'
                    : 'English',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(lang.translate('language')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            value: 'en',
                            groupValue: app.currentLocale.languageCode,
                            title: const Text('English'),
                            onChanged: (value) async {
                              Navigator.pop(context);
                              await app.setLocale(const Locale('en'));
                            },
                          ),
                          RadioListTile<String>(
                            value: 'ar',
                            groupValue: app.currentLocale.languageCode,
                            title: const Text('العربية'),
                            onChanged: (value) async {
                              Navigator.pop(context);
                              await app.setLocale(const Locale('ar'));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              _SwitchSettingsTile(
                icon: Icons.dark_mode_rounded,
                iconColor: Colors.deepPurple,
                title: lang.translate('dark_mode'),
                subtitle: app.isDarkMode
                    ? lang.translate('dark_mode_enabled')
                    : lang.translate('light_mode_enabled'),
                value: app.isDarkMode,
                onChanged: (value) async {
                  await app.toggleDarkMode(value);
                },
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: Colors.orange,
                title: lang.translate('about'),
                subtitle: lang.translate('smartcare_patient_settings'),
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
                  label: Text(
                    lang.translate('logout'),
                    style: const TextStyle(
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
                        title: Text(lang.translate('logout')),
                        content: Text(lang.translate('logout_confirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(lang.translate('cancel')),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(lang.translate('logout')),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10),
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

class _SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10),
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: PETROL,
        ),
      ),
    );
  }
}