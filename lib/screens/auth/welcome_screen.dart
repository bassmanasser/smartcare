import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/localization.dart';
import 'email_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCare'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'ar') appState.changeLanguage('ar');
              if (value == 'en') appState.changeLanguage('en');
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'ar',
                child: Text(tr.translate('arabic')),
              ),
              PopupMenuItem(
                value: 'en',
                child: Text(tr.translate('english')),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'SmartCare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Icon(
                      Icons.login_rounded,
                      size: 42,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Start here',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'First choose whether you want to login or create a new account.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmailAuthScreen(
                              startAsLogin: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_open_rounded),
                      label: Text(tr.translate('login')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmailAuthScreen(
                              startAsLogin: false,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(tr.translate('create_account')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}