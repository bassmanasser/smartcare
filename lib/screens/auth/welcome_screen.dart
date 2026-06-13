import 'package:flutter/material.dart';

import '../../utils/localization.dart';
import '../../widgets/language_picker.dart';
import 'email_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 12,
              child: IconButton.filledTonal(
                tooltip: tr.translate('language'),
                onPressed: () => showLanguagePicker(context),
                icon: const Icon(Icons.language_rounded),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 92,
                  height: 92,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.health_and_safety_rounded,
                    size: 86,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'SmartCare',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr.translate('welcome_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  tr.translate('welcome_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.68),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        tr.translate('start_here'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr.translate('choose_login_or_signup'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.72),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
