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
      'doctors': 'Doctors',
'doctor': 'Doctor',
'care_team': 'Care Team',
'welcome_back': 'Welcome back',
'device_connected_monitoring_active': 'Your device is connected and monitoring is active',
'device_disconnected_reconnect': 'Device is disconnected, reconnect to continue monitoring',
'connected': 'Connected',
'disconnected': 'Disconnected',
'heart_rate': 'Heart Rate',
'temperature': 'Temperature',
'no_linked_doctors': 'No linked doctors yet',
'primary_doctor': 'Primary Doctor',
'approved': 'Approved',
'emergency_help': 'Emergency Help',
'emergency_help_desc': 'Use this section later for emergency alerts to doctor or family.',
'emergency': 'Emergency',
'emergency_dialog_desc': 'Connect this later with a real emergency alert for doctor or family.',
'ok': 'OK',
'alert': 'Alert',
'charts': 'Charts',
'arrhythmia_check': 'Arrhythmia Check',
'resp_check': 'Resp. Check',
'account': 'Account',
'linked_doctors_family': 'Linked Doctors & Family',
'manage_requests_permissions_relationships': 'Manage requests, permissions and relationships',
'care_team_management': 'Care Team Management',
'invite_doctors_family_securely': 'Invite doctors and family members securely',
'device': 'Device',
'device_status': 'Device Status',
'connected_monitoring_active': 'Connected and monitoring is active',
'connect': 'Connect',
'disconnect': 'Disconnect',
'connecting_device': 'Connecting device...',
'device_disconnected': 'Device disconnected',
'app': 'App',
'language': 'Language',
'arabic_english': 'Arabic / English',
'about': 'About',
'smartcare_patient_settings_about': 'SmartCare patient settings and linked accounts',
'logout_confirm': 'Are you sure you want to logout?',
'cancel': 'Cancel',
'patients': 'Patients',
'sessions': 'Sessions',
'requests': 'Requests',
'rating': 'Rating',
'pending_requests': 'Pending Requests',
'no_pending_requests': 'No pending requests',
'request': 'Request',
'linked_patients': 'Linked Patients',
'no_linked_patients': 'No linked patients',
'tap_to_view_details': 'Tap to view details',
'search_patient': 'Search for a patient...',
'verified': 'Verified',
'pending': 'Pending',
'profile': 'Profile',
'edit_profile': 'Edit Profile',
'care_access_management': 'Care Access Management',
'open_incoming_requests': 'Open Incoming Requests',
'doctor_id': 'Doctor ID',
'copy': 'Copy',
'show_id': 'Show ID',
'show_qr': 'Show QR',
    },
    'ar': {
'doctors': 'الدكاترة',
'doctor': 'دكتور',
'care_team': 'الفريق الطبي',
'welcome_back': 'مرحباً بعودتك',
'device_connected_monitoring_active': 'الجهاز متصل والمراقبة تعمل الآن',
'device_disconnected_reconnect': 'الجهاز غير متصل، أعد الاتصال لمتابعة المراقبة',
'connected': 'متصل',
'disconnected': 'غير متصل',
'heart_rate': 'معدل النبض',
'temperature': 'الحرارة',
'no_linked_doctors': 'لا يوجد أطباء مرتبطون حالياً',
'primary_doctor': 'الطبيب الأساسي',
'approved': 'تمت الموافقة',
'emergency_help': 'مساعدة طارئة',
'emergency_help_desc': 'استخدمي هذا الجزء لاحقاً لإرسال تنبيه طوارئ للطبيب أو الأهل.',
'emergency': 'طوارئ',
'emergency_dialog_desc': 'اربطي هذا لاحقاً بزر طوارئ حقيقي للطبيب أو الأهل.',
'ok': 'حسنًا',
'alert': 'تنبيه',
'charts': 'الرسوم البيانية',
'arrhythmia_check': 'فحص اضطراب النظم',
'resp_check': 'فحص التنفس',
'account': 'الحساب',
'linked_doctors_family': 'الدكاترة والأهل المرتبطون',
'manage_requests_permissions_relationships': 'إدارة الطلبات والصلاحيات والعلاقات',
'care_team_management': 'إدارة الفريق الطبي',
'invite_doctors_family_securely': 'دعوة الأطباء والأهل بشكل آمن',
'device': 'الجهاز',
'device_status': 'حالة الجهاز',
'connected_monitoring_active': 'متصل والمراقبة مفعلة',
'connect': 'اتصال',
'disconnect': 'فصل',
'connecting_device': 'جارٍ توصيل الجهاز...',
'device_disconnected': 'تم فصل الجهاز',
'app': 'التطبيق',
'language': 'اللغة',
'arabic_english': 'العربية / الإنجليزية',
'about': 'حول',
'smartcare_patient_settings_about': 'إعدادات المريض والروابط في SmartCare',
'logout_confirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
'cancel': 'إلغاء',
'patients': 'المرضى',
'sessions': 'الجلسات',
'requests': 'الطلبات',
'rating': 'التقييم',
'pending_requests': 'الطلبات المعلقة',
'no_pending_requests': 'لا توجد طلبات معلقة',
'request': 'طلب',
'linked_patients': 'المرضى المرتبطون',
'no_linked_patients': 'لا يوجد مرضى مرتبطون',
'tap_to_view_details': 'اضغط لعرض التفاصيل',
'search_patient': 'ابحث عن مريض...',
'verified': 'موثق',
'pending': 'قيد المراجعة',
'profile': 'الملف الشخصي',
'edit_profile': 'تعديل الملف الشخصي',
'care_access_management': 'إدارة صلاحيات الرعاية',
'open_incoming_requests': 'فتح الطلبات الواردة',
'doctor_id': 'معرّف الطبيب',
'copy': 'نسخ',
'show_id': 'عرض المعرّف',
'show_qr': 'عرض QR',
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