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
        content: RadioGroup<String>(
          groupValue: app.currentLocale.languageCode,
          onChanged: (val) async {
            if (val == null) return;
            Navigator.pop(dialogContext);
            await app.setLocale(Locale(val));
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'en',
                title: Text(lang.translate('english')),
              ),
              RadioListTile<String>(
                value: 'ar',
                title: Text(lang.translate('arabic')),
              ),
            ],
          ),
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
