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
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading',
      'retry': 'Retry',
      'unknown': 'Unknown',
      'yes': 'Yes',
      'no': 'No',
      'add': 'Add',
      'edit': 'Edit',
      'delete': 'Delete',
      'view_all': 'View All',
      'status': 'Status',
      'name': 'Name',
      'description': 'Description',
      'date': 'Date',
      'time': 'Time',
      'today': 'Today',
      'notes': 'Notes',
      'optional': 'Optional',

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
      'invalid_credentials': 'Invalid login credentials.',
      'account_created': 'Account created successfully.',
      'login_successful': 'Logged in successfully.',
      'logout_successful': 'Logged out successfully.',

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
      'hospital_setup': 'Hospital Setup',
      'complete_hospital_registration': 'Complete Hospital Registration',
      'admin_full_name': 'Admin Full Name',
      'hospital_name': 'Hospital Name',
      'city': 'City',
      'address': 'Address',
      'complete_setup': 'Complete Setup',
      'doctor_registration': 'Doctor Registration',
      'nurse_registration': 'Nurse Registration',
      'staff_registration': 'Staff Registration',
      'submit_registration': 'Submit Registration',
      'pending_approval': 'Pending Approval',
      'waiting_for_admin_approval': 'Waiting for admin approval',

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
      'staff_approvals': 'Staff Approvals',
      'pending_staff_requests': 'Pending Staff Requests',
      'review_staff_before_approval':
          'Review doctors and nurses before adding them to your hospital.',
      'search_by_name_role_department': 'Search by name, role, department...',
      'all': 'All',
      'doctors': 'Doctors',
      'nurses': 'Nurses',
      'departments_management': 'Departments',
      'department_management': 'Department Management',
      'create_manage_departments': 'Create and manage hospital departments.',
      'dispatch_dashboard': 'Dispatch Dashboard',
      'smart_dispatch_dashboard': 'Smart Dispatch Dashboard',
      'track_routing_priority': 'Track routing, priority, and department assignment',
      'emergency_queue': 'Emergency Queue',
      'monitor_urgent_cases': 'Monitor urgent and emergency patient cases',
      'live_dispatch_cases': 'Live Dispatch Cases',

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
      'device_not_found': 'Device not found',
      'device_error': 'Device error',
      'device_not_found_error': 'Device not found / Error',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'dark_mode': 'Dark Mode',
      'dark_mode_enabled': 'Dark theme is enabled',
      'light_mode_enabled': 'Light theme is enabled',
      'smartcare_patient_settings': 'SmartCare patient settings',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'bluetooth_status': 'Bluetooth Status',
      'ble_online': 'Device online',
      'ble_offline': 'Device offline',
      'wearable_connected': 'Wearable connected',
      'wearable_disconnected': 'Wearable disconnected',
      'syncing': 'Syncing',
      'last_updated': 'Last updated',

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
      'routine': 'Routine',
      'urgent': 'Urgent',
      'critical': 'Critical',
      'stable': 'Stable',
      'improving': 'Improving',
      'under_observation': 'Under observation',
      'needs_attention': 'Needs attention',
      'serious': 'Serious',
      'assigned_to_department': 'Assigned to department',
      'awaiting_doctor': 'Awaiting doctor',
      'under_treatment': 'Under treatment',
      'follow_up': 'Follow-up',
      'discharged': 'Discharged',
      'admitted': 'Admitted',
      'transferred': 'Transferred',
      'healthy': 'Healthy',
      'mild': 'Mild',
      'moderate': 'Moderate',
      'severe': 'Severe',
      'detected': 'Detected',
      'not_detected': 'Not detected',

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

      // Mood / wellness
      'wellness_tracker': 'Wellness Tracker',
      'how_do_you_feel': 'How do you feel?',
      'happy': 'Happy',
      'neutral': 'Neutral',
      'sad': 'Sad',
      'angry': 'Angry',
      'tired': 'Tired',
      'sleep_duration': 'Sleep Duration',
      'activity': 'Activity',
      'water': 'Water',
      'add_note_optional': 'Add a note (optional)...',
      'log_my_day': 'Log My Day',
      'recent_logs': 'Recent Logs',
      'mood_saved': 'Mood saved successfully.',
      'no_logs_yet': 'No logs yet',

      // Risk / health labels
      'attention_needed': 'Attention Needed',
      'high_risk': 'High Risk',
      'emergency': 'Emergency',
      'connected': 'Connected',
      'patient_id': 'Patient ID',
      'show_report_pdf': 'Show Report PDF',
      'report_pdf': 'Report PDF',
      'pdf_not_available': 'PDF is not available',

      // Vital signs / monitoring
      'heart_rate': 'Heart Rate',
      'spo2': 'SpO2',
      'temperature': 'Temperature',
      'blood_pressure': 'Blood Pressure',
      'glucose': 'Glucose',
      'systolic': 'Systolic',
      'diastolic': 'Diastolic',
      'readings': 'Readings',
      'no_readings_yet': 'No readings yet',
      'no_reports_yet': 'No reports yet',
      'no_medications': 'No medications',
      'no_data': 'No data',

      // Arrhythmia / respiratory cases
      'arrhythmia_normal': 'Arrhythmia Normal',
      'arrhythmia_detected': 'Arrhythmia Detected',
      'tachycardia': 'Tachycardia',
      'bradycardia': 'Bradycardia',
      'af': 'Atrial Fibrillation',
      'svt': 'SVT',
      'pvc': 'PVC',
      'pac': 'PAC',
      'respiratory_normal': 'Respiratory Normal',
      'respiratory_abnormal': 'Respiratory Abnormal',
      'shortness_of_breath': 'Shortness of breath',
      'respiratory_distress': 'Respiratory distress',

      // Alert states
      'no_alerts': 'No alerts',
      'new_alert': 'New alert',
      'multiple_alerts': 'Multiple alerts',
    },

    'ar': {
      'app_name': 'SmartCare',

      // General
      'welcome': 'مرحبًا',
      'welcome_back': 'أهلاً بعودتك',
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
      'error': 'خطأ',
      'success': 'نجاح',
      'loading': 'جارٍ التحميل',
      'retry': 'إعادة المحاولة',
      'unknown': 'غير معروف',
      'yes': 'نعم',
      'no': 'لا',
      'add': 'إضافة',
      'edit': 'تعديل',
      'delete': 'حذف',
      'view_all': 'عرض الكل',
      'status': 'الحالة',
      'name': 'الاسم',
      'description': 'الوصف',
      'date': 'التاريخ',
      'time': 'الوقت',
      'today': 'اليوم',
      'notes': 'ملاحظات',
      'optional': 'اختياري',

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
      'invalid_credentials': 'بيانات تسجيل الدخول غير صحيحة.',
      'account_created': 'تم إنشاء الحساب بنجاح.',
      'login_successful': 'تم تسجيل الدخول بنجاح.',
      'logout_successful': 'تم تسجيل الخروج بنجاح.',

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
      'hospital_setup': 'إعداد المستشفى',
      'complete_hospital_registration': 'استكمال تسجيل المستشفى',
      'admin_full_name': 'الاسم الكامل للمدير',
      'hospital_name': 'اسم المستشفى',
      'city': 'المدينة',
      'address': 'العنوان',
      'complete_setup': 'إكمال الإعداد',
      'doctor_registration': 'تسجيل الدكتور',
      'nurse_registration': 'تسجيل الممرضة',
      'staff_registration': 'تسجيل الموظف',
      'submit_registration': 'إرسال التسجيل',
      'pending_approval': 'قيد المراجعة',
      'waiting_for_admin_approval': 'في انتظار موافقة المدير',

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
      'staff_approvals': 'موافقات الطاقم',
      'pending_staff_requests': 'طلبات الطاقم المعلقة',
      'review_staff_before_approval':
          'راجعي الأطباء والممرضين قبل إضافتهم إلى المستشفى.',
      'search_by_name_role_department': 'ابحثي بالاسم أو الدور أو القسم...',
      'all': 'الكل',
      'doctors': 'الأطباء',
      'nurses': 'الممرضون',
      'departments_management': 'الأقسام',
      'department_management': 'إدارة الأقسام',
      'create_manage_departments': 'إنشاء وإدارة أقسام المستشفى.',
      'dispatch_dashboard': 'لوحة التوجيه',
      'smart_dispatch_dashboard': 'لوحة التوجيه الذكية',
      'track_routing_priority': 'متابعة التوجيه والأولوية وتوزيع الأقسام',
      'emergency_queue': 'قائمة الطوارئ',
      'monitor_urgent_cases': 'متابعة الحالات العاجلة والطارئة',
      'live_dispatch_cases': 'حالات التوجيه الحالية',

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
      'device_not_found': 'الجهاز غير موجود',
      'device_error': 'خطأ في الجهاز',
      'device_not_found_error': 'الجهاز غير موجود / خطأ',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'dark_mode': 'الوضع الداكن',
      'dark_mode_enabled': 'تم تفعيل الوضع الداكن',
      'light_mode_enabled': 'تم تفعيل الوضع الفاتح',
      'smartcare_patient_settings': 'إعدادات المريض في SmartCare',
      'logout': 'تسجيل الخروج',
      'logout_confirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      'bluetooth_status': 'حالة البلوتوث',
      'ble_online': 'الجهاز متصل',
      'ble_offline': 'الجهاز غير متصل',
      'wearable_connected': 'السوار متصل',
      'wearable_disconnected': 'السوار غير متصل',
      'syncing': 'جارٍ المزامنة',
      'last_updated': 'آخر تحديث',

      // Patient home / profile / workflow
      'patient_profile': 'الملف الشخصي للمريض',
      'institution_workflow_title': 'مسار الحالة داخل المؤسسة',
      'current_health_status': 'الحالة الصحية الحالية',
      'queue_priority': 'أولوية الدور',
      'stage': 'المرحلة',
      'case_status': 'حالة المريض',
      'score': 'الدرجة',
      'quick_access': 'وصول سريع',
      'care_team': 'فريق الرعاية',
      'my_qr': 'رمز QR الخاص بي',
      'normal': 'طبيعي',
      'abnormal': 'غير طبيعي',
      'arrhythmia': 'اضطراب النبض',
      'respiratory': 'التنفس',
      'alerts': 'التنبيهات',
      'not_assigned_yet': 'لم يتم التحديد بعد',
      'pending_triage': 'في انتظار الفرز',
      'patient_intake': 'استقبال المريض',
      'age': 'العمر',
      'gender': 'النوع',
      'routine': 'عادية',
      'urgent': 'عاجلة',
      'critical': 'حرجة',
      'stable': 'مستقرة',
      'improving': 'تتحسن',
      'under_observation': 'تحت الملاحظة',
      'needs_attention': 'تحتاج متابعة',
      'serious': 'خطيرة',
      'assigned_to_department': 'تم التوجيه إلى القسم',
      'awaiting_doctor': 'في انتظار الطبيب',
      'under_treatment': 'تحت العلاج',
      'follow_up': 'متابعة',
      'discharged': 'تم الخروج',
      'admitted': 'تم الإدخال',
      'transferred': 'تم التحويل',
      'healthy': 'جيدة',
      'mild': 'خفيفة',
      'moderate': 'متوسطة',
      'severe': 'شديدة',
      'detected': 'تم الاكتشاف',
      'not_detected': 'لم يتم الاكتشاف',

      // Services
      'reports': 'التقارير',
      'doctor_notes': 'ملاحظات الطبيب',
      'medications': 'الأدوية',
      'mood': 'الحالة المزاجية',
      'charts': 'الرسوم البيانية',
      'alerts_history': 'سجل التنبيهات',
      'ai_bot': 'المساعد الذكي',
      'arrhythmia_check': 'فحص اضطراب النبض',
      'resp_check': 'فحص التنفس',

      // Mood / wellness
      'wellness_tracker': 'متابعة الحالة اليومية',
      'how_do_you_feel': 'كيف تشعر اليوم؟',
      'happy': 'سعيد',
      'neutral': 'محايد',
      'sad': 'حزين',
      'angry': 'غاضب',
      'tired': 'متعب',
      'sleep_duration': 'مدة النوم',
      'activity': 'النشاط',
      'water': 'الماء',
      'add_note_optional': 'أضف ملاحظة (اختياري)...',
      'log_my_day': 'سجل يومي',
      'recent_logs': 'السجلات الأخيرة',
      'mood_saved': 'تم حفظ الحالة المزاجية بنجاح.',
      'no_logs_yet': 'لا توجد سجلات بعد',

      // Risk / health labels
      'attention_needed': 'تحتاج انتباه',
      'high_risk': 'خطورة عالية',
      'emergency': 'طارئة',
      'connected': 'متصل',
      'patient_id': 'معرّف المريض',
      'show_report_pdf': 'عرض التقرير PDF',
      'report_pdf': 'تقرير PDF',
      'pdf_not_available': 'ملف PDF غير متاح',

      // Vital signs / monitoring
      'heart_rate': 'معدل النبض',
      'spo2': 'تشبع الأكسجين',
      'temperature': 'الحرارة',
      'blood_pressure': 'ضغط الدم',
      'glucose': 'الجلوكوز',
      'systolic': 'الضغط الانقباضي',
      'diastolic': 'الضغط الانبساطي',
      'readings': 'القراءات',
      'no_readings_yet': 'لا توجد قراءات بعد',
      'no_reports_yet': 'لا توجد تقارير بعد',
      'no_medications': 'لا توجد أدوية',
      'no_data': 'لا توجد بيانات',

      // Arrhythmia / respiratory cases
      'arrhythmia_normal': 'النبض طبيعي',
      'arrhythmia_detected': 'تم اكتشاف اضطراب بالنبض',
      'tachycardia': 'تسارع في النبض',
      'bradycardia': 'بطء في النبض',
      'af': 'رجفان أذيني',
      'svt': 'تسرع فوق بطيني',
      'pvc': 'انقباضات بطينية مبكرة',
      'pac': 'انقباضات أذينية مبكرة',
      'respiratory_normal': 'التنفس طبيعي',
      'respiratory_abnormal': 'التنفس غير طبيعي',
      'shortness_of_breath': 'ضيق في التنفس',
      'respiratory_distress': 'إجهاد تنفسي',

      // Alert states
      'no_alerts': 'لا توجد تنبيهات',
      'new_alert': 'تنبيه جديد',
      'multiple_alerts': 'عدة تنبيهات',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String localizeDynamicValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return translate('unknown');
    }

    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'routine':
        return translate('routine');
      case 'urgent':
        return translate('urgent');
      case 'emergency':
        return translate('emergency');
      case 'critical':
        return translate('critical');

      case 'normal':
        return translate('normal');
      case 'abnormal':
        return translate('abnormal');
      case 'stable':
        return translate('stable');
      case 'improving':
        return translate('improving');
      case 'under observation':
        return translate('under_observation');
      case 'needs attention':
        return translate('needs_attention');
      case 'serious':
        return translate('serious');
      case 'healthy':
        return translate('healthy');
      case 'mild':
        return translate('mild');
      case 'moderate':
        return translate('moderate');
      case 'severe':
        return translate('severe');

      case 'not assigned yet':
        return translate('not_assigned_yet');
      case 'pending triage':
        return translate('pending_triage');
      case 'patient intake':
        return translate('patient_intake');
      case 'assigned to department':
        return translate('assigned_to_department');
      case 'awaiting doctor':
        return translate('awaiting_doctor');
      case 'under treatment':
        return translate('under_treatment');
      case 'follow-up':
      case 'follow up':
        return translate('follow_up');
      case 'discharged':
        return translate('discharged');
      case 'admitted':
        return translate('admitted');
      case 'transferred':
        return translate('transferred');

      case 'disconnected':
        return translate('disconnected');
      case 'connected':
        return translate('connected');
      case 'device not found':
        return translate('device_not_found');
      case 'device error':
        return translate('device_error');
      case 'device not found / error':
        return translate('device_not_found_error');

      case 'arrhythmia':
        return translate('arrhythmia');
      case 'respiratory':
        return translate('respiratory');
      case 'alerts':
        return translate('alerts');

      case 'happy':
        return translate('happy');
      case 'neutral':
        return translate('neutral');
      case 'sad':
        return translate('sad');
      case 'angry':
        return translate('angry');
      case 'tired':
        return translate('tired');

      case 'tachycardia':
        return translate('tachycardia');
      case 'bradycardia':
        return translate('bradycardia');
      case 'af':
        return translate('af');
      case 'svt':
        return translate('svt');
      case 'pvc':
        return translate('pvc');
      case 'pac':
        return translate('pac');

      case 'detected':
        return translate('detected');
      case 'not detected':
        return translate('not_detected');

      default:
        return value;
    }
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