import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        ) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'SmartCare',

      // General
      'welcome': 'Welcome',
      'welcome_back': 'Welcome back',
      'home': 'Home',
      'profile': 'Profile',
      'services': 'Services',
      'settings': 'Settings',
      'account': 'Account',
      'app': 'App',
      'device': 'Device',
      'about': 'About',
      'save': 'Save',
      'cancel': 'Cancel',
      'done': 'Done',
      'close': 'Close',
      'search': 'Search',
      'refresh': 'Refresh',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'copied': 'Copied',

      // User type / welcome
      'choose_role': 'Choose Role',
      'select_how_to_use': 'Select how you want to use SmartCare',
      'patient': 'Patient',
      'parent': 'Parent',
      'doctor': 'Doctor',
      'nurse': 'Nurse',
      'triage_staff': 'Triage Staff',
      'support_staff': 'Support Staff',
      'staff': 'Staff',
      'hospital_admin': 'Hospital Admin',
      'medical_staff': 'Medical Staff',
      'institution_workflow':
          'Medical staff are registered under a hospital / institution workflow.',

      // Auth
      'login': 'Login',
      'signup': 'Sign Up',
      'create_account': 'Create Account',
      'registration': 'Registration',
      'email': 'Email',
      'password': 'Password',
      'full_name': 'Full Name',
      'phone': 'Phone',
      'work_phone': 'Work Phone',
      'already_have_account': 'Already have an account? Login',
      'dont_have_account': "Don't have an account? Sign up",
      'invalid_email_password': 'Invalid email or password (minimum 6 chars).',
      'please_fill_required': 'Please fill all required fields.',
      'role_locked': 'Role already set and cannot be changed.',

      // Institution / staff registration
      'institution_name': 'Hospital / Institution Name',
      'institution_address': 'Hospital Address',
      'institution_city': 'City',
      'institution': 'Institution',
      'hospital_id': 'Hospital ID',
      'copy_hospital_id': 'Copy Hospital ID',
      'show_hospital_id': 'Show Hospital ID',
      'department': 'Department',
      'departments': 'Departments',
      'employee_id': 'Employee ID',
      'license_number': 'License Number',
      'medical_role': 'Medical Role',
      'institution_not_found': 'Hospital ID not found.',
      'profile_saved': 'Profile saved successfully.',

      // Approval / dashboard
      'dashboard': 'Dashboard',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'pending_requests': 'Pending Requests',
      'staff_members': 'Staff Members',
      'quick_actions': 'Quick Actions',
      'approve': 'Approve',
      'reject': 'Reject',
      'no_pending_requests': 'No pending requests',
      'assigned_patients': 'Assigned Patients',
      'latest_alerts': 'Latest Alerts',
      'active_cases': 'Active Cases',
      'incoming_queue': 'Incoming Queue',
      'severity': 'Severity',
      'priority': 'Priority',
      'save_continue': 'Save & Continue',

      // Role descriptions
      'hospital_admin_desc': 'Register a hospital and manage approvals',
      'doctor_desc': 'Doctor under hospital system',
      'nurse_desc': 'Nurse under hospital system',
      'triage_desc': 'Triage / dispatch staff',
      'staff_desc': 'General hospital support staff',
      'patient_desc': 'Vitals, alerts, reports and monitoring',
      'parent_desc': 'Follow patient updates and status',

      // Patient app / settings
      'my_qr_code': 'My QR Code',
      'show_qr_for_doctor_scan': 'Show your QR code for doctor scan',
      'device_status': 'Device Status',
      'connected_monitoring_active': 'Connected - monitoring is active',
      'disconnected': 'Disconnected',
      'connecting_device': 'Connecting to device...',
      'device_disconnected': 'Device disconnected',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'dark_mode': 'Dark Mode',
      'dark_mode_enabled': 'Dark theme is enabled',
      'light_mode_enabled': 'Light theme is enabled',
      'smartcare_patient_settings': 'SmartCare patient settings',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',

      // Patient home / profile / workflow
      'patient_profile': 'Patient Profile',
      'institution_workflow_title': 'Institution Workflow',
      'current_health_status': 'Current Health Status',
      'queue_priority': 'Queue Priority',
      'stage': 'Stage',
      'case_status': 'Case status',
      'score': 'Score',
      'quick_access': 'Quick Access',
      'care_team': 'Care Team',
      'my_qr': 'My QR',
      'normal': 'Normal',
      'abnormal': 'Abnormal',
      'arrhythmia': 'Arrhythmia',
      'respiratory': 'Respiratory',
      'alerts': 'Alerts',
      'not_assigned_yet': 'Not assigned yet',
      'pending_triage': 'Pending triage',
      'patient_intake': 'Patient intake',
      'age': 'Age',
      'gender': 'Gender',

      // Services
      'reports': 'Reports',
      'doctor_notes': 'Doctor Notes',
      'medications': 'Medications',
      'mood': 'Mood',
      'charts': 'Charts',
      'alerts_history': 'Alerts History',
      'ai_bot': 'AI Bot',
      'arrhythmia_check': 'Arrhythmia Check',
      'resp_check': 'Resp. Check',

      // Risk / health labels
      'attention_needed': 'Attention Needed',
      'high_risk': 'High Risk',
      'emergency': 'Emergency',
      'connected': 'Connected',
      'bluetooth_status': 'Bluetooth Status',
      'patient_id': 'Patient ID',
      'show_report_pdf': 'Show Report PDF',
      'report_pdf': 'Report PDF',
      'pdf_not_available': 'PDF is not available',
    },

    'ar': {
      'app_name': 'SmartCare',

      // General
      'welcome': 'مرحبًا',
      'welcome_back': 'مرحبًا بعودتك',
      'home': 'الرئيسية',
      'profile': 'الملف الشخصي',
      'services': 'الخدمات',
      'settings': 'الإعدادات',
      'account': 'الحساب',
      'app': 'التطبيق',
      'device': 'الجهاز',
      'about': 'حول التطبيق',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'done': 'تم',
      'close': 'إغلاق',
      'search': 'بحث',
      'refresh': 'تحديث',
      'connect': 'اتصال',
      'disconnect': 'فصل',
      'copied': 'تم النسخ',

      // User type / welcome
      'choose_role': 'اختيار الدور',
      'select_how_to_use': 'اختاري طريقة استخدام SmartCare',
      'patient': 'مريض',
      'parent': 'ولي أمر',
      'doctor': 'دكتور',
      'nurse': 'ممرضة',
      'triage_staff': 'طاقم الفرز',
      'support_staff': 'موظف دعم',
      'staff': 'الموظفون',
      'hospital_admin': 'مدير المستشفى',
      'medical_staff': 'الطاقم الطبي',
      'institution_workflow':
          'الطاقم الطبي يتم تسجيله تحت مستشفى / مؤسسة طبية.',

      // Auth
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'create_account': 'إنشاء حساب',
      'registration': 'التسجيل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'full_name': 'الاسم الكامل',
      'phone': 'رقم الهاتف',
      'work_phone': 'هاتف العمل',
      'already_have_account': 'لديك حساب بالفعل؟ سجلي الدخول',
      'dont_have_account': 'ليس لديك حساب؟ أنشئي حسابًا',
      'invalid_email_password':
          'البريد الإلكتروني أو كلمة المرور غير صالحين (6 أحرف على الأقل).',
      'please_fill_required': 'من فضلك املئي كل الحقول المطلوبة.',
      'role_locked': 'تم تثبيت الدور بالفعل ولا يمكن تغييره.',

      // Institution / staff registration
      'institution_name': 'اسم المستشفى / المؤسسة',
      'institution_address': 'عنوان المستشفى',
      'institution_city': 'المدينة',
      'institution': 'المؤسسة',
      'hospital_id': 'معرّف المستشفى',
      'copy_hospital_id': 'نسخ معرّف المستشفى',
      'show_hospital_id': 'عرض معرّف المستشفى',
      'department': 'القسم',
      'departments': 'الأقسام',
      'employee_id': 'الرقم الوظيفي',
      'license_number': 'رقم الترخيص',
      'medical_role': 'الدور الطبي',
      'institution_not_found': 'معرّف المستشفى غير موجود.',
      'profile_saved': 'تم حفظ البيانات بنجاح.',

      // Approval / dashboard
      'dashboard': 'لوحة التحكم',
      'pending': 'قيد المراجعة',
      'approved': 'تمت الموافقة',
      'rejected': 'مرفوض',
      'pending_requests': 'الطلبات المعلقة',
      'staff_members': 'أفراد الطاقم',
      'quick_actions': 'إجراءات سريعة',
      'approve': 'موافقة',
      'reject': 'رفض',
      'no_pending_requests': 'لا توجد طلبات معلقة',
      'assigned_patients': 'المرضى المكلّفون',
      'latest_alerts': 'أحدث التنبيهات',
      'active_cases': 'الحالات النشطة',
      'incoming_queue': 'قائمة الحالات الواردة',
      'severity': 'الخطورة',
      'priority': 'الأولوية',
      'save_continue': 'حفظ واستكمال',

      // Role descriptions
      'hospital_admin_desc': 'تسجيل مستشفى وإدارة الموافقات',
      'doctor_desc': 'دكتور تابع للمستشفى',
      'nurse_desc': 'ممرضة تابعة للمستشفى',
      'triage_desc': 'موظف فرز وتوجيه',
      'staff_desc': 'موظف دعم عام بالمستشفى',
      'patient_desc': 'القراءات والتنبيهات والتقارير والمتابعة',
      'parent_desc': 'متابعة حالة المريض',

      // Patient app / settings
      'my_qr_code': 'رمز QR الخاص بي',
      'show_qr_for_doctor_scan': 'اعرض رمز QR ليقوم الطبيب بمسحه',
      'device_status': 'حالة الجهاز',
      'connected_monitoring_active': 'متصل - المراقبة فعالة',
      'disconnected': 'غير متصل',
      'connecting_device': 'جارٍ الاتصال بالجهاز...',
      'device_disconnected': 'تم فصل الجهاز',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'dark_mode': 'الوضع الداكن',
      'dark_mode_enabled': 'تم تفعيل الوضع الداكن',
      'light_mode_enabled': 'تم تفعيل الوضع الفاتح',
      'smartcare_patient_settings': 'إعدادات المريض في SmartCare',
      'logout': 'تسجيل الخروج',
      'logout_confirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',

      // Patient home / profile / workflow
      'patient_profile': 'الملف الشخصي للمريض',
      'institution_workflow_title': 'مسار المؤسسة الطبية',
      'current_health_status': 'الحالة الصحية الحالية',
      'queue_priority': 'أولوية الدور',
      'stage': 'المرحلة',
      'case_status': 'حالة الحالة',
      'score': 'النتيجة',
      'quick_access': 'وصول سريع',
      'care_team': 'فريق الرعاية',
      'my_qr': 'رمز QR الخاص بي',
      'normal': 'طبيعي',
      'abnormal': 'غير طبيعي',
      'arrhythmia': 'اضطراب النظم',
      'respiratory': 'التنفس',
      'alerts': 'التنبيهات',
      'not_assigned_yet': 'لم يتم التعيين بعد',
      'pending_triage': 'بانتظار الفرز',
      'patient_intake': 'استقبال المريض',
      'age': 'العمر',
      'gender': 'النوع',

      // Services
      'reports': 'التقارير',
      'doctor_notes': 'ملاحظات الطبيب',
      'medications': 'الأدوية',
      'mood': 'الحالة المزاجية',
      'charts': 'الرسوم البيانية',
      'alerts_history': 'سجل التنبيهات',
      'ai_bot': 'المساعد الذكي',
      'arrhythmia_check': 'فحص اضطراب النظم',
      'resp_check': 'فحص التنفس',

      // Risk / health labels
      'attention_needed': 'يحتاج انتباه',
      'high_risk': 'خطورة عالية',
      'emergency': 'طارئ',
      'connected': 'متصل',
      'bluetooth_status': 'حالة البلوتوث',
      'patient_id': 'معرّف المريض',
      'show_report_pdf': 'عرض ملف التقرير PDF',
      'report_pdf': 'تقرير PDF',
      'pdf_not_available': 'ملف الـ PDF غير متاح',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}