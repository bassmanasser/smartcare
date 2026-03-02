import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'SmartCare',
      'home': 'Home',
      'services': 'Services',
      'settings': 'Settings',
      'welcome': 'Welcome',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'hr': 'Heart Rate',
      'spo2': 'Oxygen',
      'bp': 'Blood Pressure',
      'glucose': 'Glucose',
      'temp': 'Temperature',
      'sos': 'SOS',
      'sos_sent': 'SOS Alert Sent!',
      'medications': 'Medications',
      'doctor_notes': 'Doctor Notes',
      'mood': 'Mood',
      'reports': 'Reports',
      'alerts_history': 'Alerts History',
      'ai_bot': 'AI Assistant',
      'connect_device': 'Connect Device',
      'disconnect': 'Disconnect',
      'save': 'Save',
      'logout': 'Logout',
      'change_lang': 'Change Language',
    },
    'ar': {
      'app_title': 'رعايتي (SmartCare)',
      'home': 'الرئيسية',
      'services': 'الخدمات',
      'settings': 'الإعدادات',
      'welcome': 'مرحباً',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'hr': 'نبض القلب',
      'spo2': 'الأكسجين',
      'bp': 'ضغط الدم',
      'glucose': 'السكر',
      'temp': 'الحرارة',
      'sos': 'استغاثة (SOS)',
      'sos_sent': 'تم إرسال الاستغاثة بنجاح!',
      'medications': 'الأدوية',
      'doctor_notes': 'ملاحظات الطبيب',
      'mood': 'الحالة المزاجية',
      'reports': 'التقارير',
      'alerts_history': 'سجل التنبيهات',
      'ai_bot': 'المساعد الذكي',
      'connect_device': 'ربط الجهاز',
      'disconnect': 'فصل الاتصال',
      'save': 'حفظ',
      'logout': 'خروج',
      'change_lang': 'تغيير اللغة',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}