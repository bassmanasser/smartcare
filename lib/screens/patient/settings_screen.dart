import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/auth_service.dart';
import '../../utils/localization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(L10n.get(context, 'settings', onChanged: (String? value) {  }))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(L10n.get(context, 'toggleLang', onChanged: (String? value) {  })),
            trailing: const Icon(Icons.language),
            onTap: () {
              app.toggleLocale();
            },
          ),
          const Divider(),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => auth.signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text("Sign Out"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}