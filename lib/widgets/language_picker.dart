import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/localization.dart';

Future<void> showLanguagePicker(BuildContext context) async {
  final app = context.read<AppState>();
  final lang = AppLocalizations.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(lang.translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'en',
              groupValue: app.currentLocale.languageCode,
              title: Text(lang.translate('english')),
              onChanged: (_) async {
                Navigator.pop(dialogContext);
                await app.setLocale(const Locale('en'));
              },
            ),
            RadioListTile<String>(
              value: 'ar',
              groupValue: app.currentLocale.languageCode,
              title: Text(lang.translate('arabic')),
              onChanged: (_) async {
                Navigator.pop(dialogContext);
                await app.setLocale(const Locale('ar'));
              },
            ),
          ],
        ),
      );
    },
  );
}

String currentLanguageLabel(BuildContext context) {
  final app = context.watch<AppState>();
  final lang = AppLocalizations.of(context);
  return app.currentLocale.languageCode == 'ar'
      ? lang.translate('arabic')
      : lang.translate('english');
}
