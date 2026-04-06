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
      'choose_role': 'Choose Role',
      'select_how_to_use': 'Select how you want to use SmartCare',
      'patient': 'Patient',
      'parent': 'Parent',
      'doctor': 'Doctor',
      'nurse': 'Nurse',
      'triage_staff': 'Triage Staff',
      'support_staff': 'Support Staff',
      'hospital_admin': 'Hospital Admin',
      'medical_staff': 'Medical Staff',
      'institution_workflow':
          'Medical staff are registered under a hospital / institution workflow.',
      'login': 'Login',
      'signup': 'Sign Up',
      'create_account': 'Create Account',
      'email': 'Email',
      'password': 'Password',
      'full_name': 'Full Name',
      'phone': 'Phone',
      'work_phone': 'Work Phone',
      'institution_name': 'Hospital / Institution Name',
      'institution_address': 'Hospital Address',
      'institution_city': 'City',
      'department': 'Department',
      'employee_id': 'Employee ID',
      'license_number': 'License Number',
      'medical_role': 'Medical Role',
      'hospital_id': 'Hospital ID',
      'copy_hospital_id': 'Copy Hospital ID',
      'show_hospital_id': 'Show Hospital ID',
      'registration': 'Registration',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'logout': 'Logout',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'dashboard': 'Dashboard',
      'pending_requests': 'Pending Requests',
      'staff_members': 'Staff Members',
      'departments': 'Departments',
      'institution': 'Institution',
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
      'already_have_account': 'Already have an account? Login',
      'dont_have_account': "Don't have an account? Sign up",
      'invalid_email_password': 'Invalid email or password (minimum 6 chars).',
      'please_fill_required': 'Please fill all required fields.',
      'institution_not_found': 'Hospital ID not found.',
      'profile_saved': 'Profile saved successfully.',
      'copied': 'Copied',
      'welcome': 'Welcome',
      'hospital_admin_desc': 'Register a hospital and manage approvals',
      'doctor_desc': 'Doctor under hospital system',
      'nurse_desc': 'Nurse under hospital system',
      'triage_desc': 'Triage / dispatch staff',
      'staff_desc': 'General hospital support staff',
      'patient_desc': 'Vitals, alerts, reports and monitoring',
      'parent_desc': 'Follow patient updates and status',
      'role_locked': 'Role already set and cannot be changed.',
    },
    'ar': {
      'app_name': 'SmartCare',
      'choose_role': 'اختيار الدور',
      'select_how_to_use': 'اختاري طريقة استخدام SmartCare',
      'patient': 'مريض',
      'parent': 'ولي أمر',
      'doctor': 'دكتور',
      'nurse': 'ممرضة',
      'triage_staff': 'طاقم الفرز',
      'support_staff': 'موظف مستشفى',
      'hospital_admin': 'مدير المستشفى',
      'medical_staff': 'الطاقم الطبي',
      'institution_workflow':
          'الطاقم الطبي يتم تسجيله تحت مستشفى / مؤسسة طبية.',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'create_account': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'full_name': 'الاسم الكامل',
      'phone': 'رقم الهاتف',
      'work_phone': 'هاتف العمل',
      'institution_name': 'اسم المستشفى / المؤسسة',
      'institution_address': 'عنوان المستشفى',
      'institution_city': 'المدينة',
      'department': 'القسم',
      'employee_id': 'الرقم الوظيفي',
      'license_number': 'رقم الترخيص',
      'medical_role': 'الدور الطبي',
      'hospital_id': 'معرّف المستشفى',
      'copy_hospital_id': 'نسخ معرّف المستشفى',
      'show_hospital_id': 'عرض معرّف المستشفى',
      'registration': 'التسجيل',
      'pending': 'قيد المراجعة',
      'approved': 'تمت الموافقة',
      'rejected': 'مرفوض',
      'logout': 'تسجيل الخروج',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'dashboard': 'لوحة التحكم',
      'pending_requests': 'الطلبات المعلقة',
      'staff_members': 'أفراد الطاقم',
      'departments': 'الأقسام',
      'institution': 'المؤسسة',
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
      'already_have_account': 'لديك حساب بالفعل؟ سجلي الدخول',
      'dont_have_account': 'ليس لديك حساب؟ أنشئي حسابًا',
      'invalid_email_password':
          'البريد الإلكتروني أو كلمة المرور غير صالحين (6 أحرف على الأقل).',
      'please_fill_required': 'من فضلك املئي كل الحقول المطلوبة.',
      'institution_not_found': 'معرّف المستشفى غير موجود.',
      'profile_saved': 'تم حفظ البيانات بنجاح.',
      'copied': 'تم النسخ',
      'welcome': 'مرحبًا',
      'hospital_admin_desc': 'تسجيل مستشفى وإدارة الموافقات',
      'doctor_desc': 'دكتور تابع للمستشفى',
      'nurse_desc': 'ممرضة تابعة للمستشفى',
      'triage_desc': 'موظف فرز وتوجيه',
      'staff_desc': 'موظف دعم عام بالمستشفى',
      'patient_desc': 'القراءات والتنبيهات والتقارير',
      'parent_desc': 'متابعة حالة المريض',
      'role_locked': 'تم تثبيت الدور بالفعل ولا يمكن تغييره.',
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