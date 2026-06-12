import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
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
      'critical_alert': 'Critical Alert',
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
      'start_here': 'Start here',
      'choose_login_or_signup':
          'First choose whether you want to login or create a new account.',
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
      'track_routing_priority':
          'Track routing, priority, and department assignment',
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
      'update_my_data': 'Update my data',
      'update_my_data_desc':
          'Edit personal, emergency, and medical profile data',
      'my_qr_code': 'My QR Code',
      'show_qr_for_doctor_scan': 'Show your QR code for doctor scan',
      'device_status': 'Device Status',
      'device_connected': 'Device connected',
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
      'latest_readings': 'Latest Readings',
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
      'start_chatting': 'Start chatting with your health assistant',
      'ask_about_your_health': 'Ask about your health...',
      'please_login_first': 'Please log in first.',
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

      // Charts / time aggregation
      'chart_mode_live': 'Live readings',
      'chart_mode_hourly': 'Hourly averages',
      'chart_mode_daily': 'Daily averages',
      'high': 'High',
      'low': 'Low',
      'danger': 'Danger',
      'elevated': 'Elevated',
      'fever': 'Fever',
      'high_fever': 'High Fever',

      // Admin screen
      'overview': 'Overview',
      'hospital_overview_subtitle': 'Quick summary of your hospital today',
      'patients_today': 'Patients Today',
      'patients_today_subtitle': 'Patients who arrived today.',
      'pending_approvals': 'Pending Approvals',
      'emergency_cases': 'Emergency Cases',
      'latest_alerts_subtitle': 'Recent patient alerts',
      'no_alerts_yet': 'No alerts yet',
      'all_stable': 'Everything looks stable.',
      'hospital_services_subtitle': 'Hospital management tools',
      'admit_patient': 'Admit Patient',
      'admit_patient_subtitle': 'Register and admit a new patient.',
      'staff_approvals_subtitle_admin': 'Review pending doctors and nurses.',
      'departments_subtitle': 'Manage hospital departments.',
      'emergency_queue_subtitle': 'Track urgent patient cases.',
      'dispatch_dashboard_subtitle': 'Monitor smart dispatching.',
      'doctors_list': 'Doctors List',
      'doctors_list_subtitle': 'All doctors in this hospital.',
      'nurses_list': 'Nurses List',
      'nurses_list_subtitle': 'All nurses in this hospital.',
      'hospital_profile': 'Hospital Profile',
      'hospital_profile_subtitle': 'Institutional identity',
      'open_full_hospital_profile': 'Open Full Hospital Profile',
      'admin_settings_subtitle': 'Account and dashboard options',
      'refresh_data': 'Refresh Data',
      'refresh_data_subtitle': 'Reload information',
      'hospital_profile_settings_subtitle': 'View hospital details',
      'logout_admin_subtitle': 'Sign out from dashboard',
      'hospital_id_label': 'Hospital ID',
      'hospital_label': 'Hospital',
      'admin_label': 'Admin',

      // Doctor screen
      'specialty': 'Specialty',
      'general': 'General',
      'clinical_work': 'Clinical Work',
      'assigned_cases': 'Assigned Cases',
      'requests_and_notes': 'Requests & Notes',
      'scan_patient_qr': 'Scan Patient QR',
      'critical_queue': 'Critical Queue',
      'no_critical_cases': 'No critical cases',
      'institution_status': 'Institution Status',
      'doctor_profile': 'Doctor Profile',
      'approval_status': 'Approval Status',
      'role_label': 'Role',
      'staff_id_label': 'Staff ID',
      'approval_label': 'Approval',
      'patients_label': 'Patients',
      'urgent_label': 'Urgent',
      'requests_menu': 'Requests',
      'doctor_profile_subtitle': 'Identity, hospital data, and registration details',
      'doctor_settings_subtitle': 'Doctor account options and system access',
      'clinical_work_subtitle': 'Open cases and clinical notes',
      'assigned_cases_subtitle': 'Manage your assigned patient cases',
      'requests_and_notes_subtitle': 'Patient requests and follow-up notes',
      'scan_patient_qr_subtitle': 'Link a patient by scanning their QR code',
      'critical_queue_subtitle': 'Emergency and urgent priority cases',
      'no_critical_cases_subtitle': 'All patients are stable',
      'doctor_requests_subtitle': 'Open doctor requests and follow-ups',
      'institution_status_subtitle': 'Doctor role and hospital registration summary',

      // Nurse / Staff shared
      'nursing_work': 'Nursing Work',
      'staff_work': 'Staff Work',
      'my_patients': 'My Patients',
      'active_cases_label': 'Active Cases',
      'assigned_patients_label': 'Assigned Patients',
      'nurse_profile': 'Nurse Profile',
      'staff_profile': 'Staff Profile',
      'parent_profile': 'Parent Profile',
      'open_cases': 'Open Cases',
      'nurse_overview_subtitle': 'Professional nurse dashboard summary',
      'nursing_work_subtitle': 'Main nurse tools and actions',
      'nurse_profile_subtitle': 'Identity, department, and hospital registration details',
      'nurse_settings_subtitle': 'Nurse account options',
      'nurse_scan_subtitle': 'Link a patient by scanning QR or entering patient ID',
      'my_patients_subtitle': 'Open patient list assigned to this nurse',
      'nurse_logout_subtitle': 'Sign out from nurse account',
      'nurse_refresh_subtitle': 'Reload nurse dashboard data',
      'staff_overview_subtitle': 'Staff dashboard and active case summary',
      'staff_work_subtitle': 'Main staff tools and actions',
      'staff_profile_subtitle': 'Identity, department, and hospital registration details',
      'staff_settings_subtitle': 'Staff account options',
      'staff_logout_subtitle': 'Sign out from staff account',
      'staff_refresh_subtitle': 'Reload staff dashboard data',
      'staff_scan_subtitle': 'Link a patient by scanning QR or entering patient ID',
      'staff_patients_subtitle': 'Open patient list assigned to this staff member',

      // Parent screen
      'linked_patients': 'Linked Patients',
      'no_linked_patients': 'No patients linked yet',
      'scan_to_link': 'Scan QR to link a patient',
      'view_patient': 'View Patient',
      'unlink': 'Unlink',
      'unlink_confirm': 'Remove this patient from your linked list?',
      'parent_dashboard': 'Parent Dashboard',
      'family_monitoring': 'Family Monitoring',
      'parent_track_subtitle': 'Track your children, alerts, and daily health status',
      'family_follow_up': 'Family follow-up account',
      'children': 'Children',
      'notifications': 'Notifications',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'critical_only': 'Critical Only',
      'children_status': 'Children Status',
      'scan_qr': 'Scan QR',
      'link_patient_subtitle': 'Link a patient account',
      'critical_cases_first': 'Critical cases first',
      'medical_pdf_subtitle': 'Medical PDF / summaries',
      'call_doctor_subtitle': 'Call or message doctor',
      'profile_preferences_subtitle': 'Profile and preferences',
      'report_button': 'Report',
      'no_linked_children': 'No linked children yet',
      'no_linked_children_desc': 'Once a patient is connected to this parent account, the child profile will appear here.',
      'follow_up_profile': 'Follow-up profile',
      'real_time_follow_up': 'Real-time follow up',
      'linked': 'linked',
    },

    'ar': {
      'app_name': 'SmartCare',

      // General
      'welcome': 'مرحبًا',
      'welcome_back': 'أهلاً بعودتك',
      'home': 'الرئيسية',
      'profile': 'الملف الشخصي',
      'critical_alert': 'تنبيه حرج',
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
      'device_connected': 'الجهاز متصل',
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
      'latest_readings': 'آخر القراءات',
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
      'start_chatting': 'ابدئي المحادثة مع المساعد الصحي',
      'ask_about_your_health': 'اسألي عن صحتك...',
      'please_login_first': 'من فضلك سجلي الدخول أولاً.',
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

      // Charts / time aggregation
      'chart_mode_live': 'قراءات حية',
      'chart_mode_hourly': 'متوسط كل ساعة',
      'chart_mode_daily': 'متوسط يومي',
      'high': 'مرتفع',
      'low': 'منخفض',
      'danger': 'خطر',
      'elevated': 'مرتفع قليلاً',
      'fever': 'حمى',
      'high_fever': 'حمى شديدة',

      // Admin screen
      'overview': 'نظرة عامة',
      'hospital_overview_subtitle': 'ملخص سريع عن مستشفاك اليوم',
      'patients_today': 'مرضى اليوم',
      'patients_today_subtitle': 'المرضى الذين وصلوا اليوم.',
      'pending_approvals': 'الموافقات المعلقة',
      'emergency_cases': 'حالات الطوارئ',
      'latest_alerts_subtitle': 'تنبيهات المرضى الأخيرة',
      'no_alerts_yet': 'لا توجد تنبيهات بعد',
      'all_stable': 'كل شيء يبدو مستقراً.',
      'hospital_services_subtitle': 'أدوات إدارة المستشفى',
      'admit_patient': 'استقبال مريض',
      'admit_patient_subtitle': 'تسجيل وقبول مريض جديد.',
      'staff_approvals_subtitle_admin': 'راجع طلبات الأطباء والممرضين.',
      'departments_subtitle': 'إدارة أقسام المستشفى.',
      'emergency_queue_subtitle': 'تتبع الحالات العاجلة.',
      'dispatch_dashboard_subtitle': 'مراقبة الإحالات الذكية.',
      'doctors_list': 'قائمة الأطباء',
      'doctors_list_subtitle': 'جميع الأطباء في هذا المستشفى.',
      'nurses_list': 'قائمة الممرضات',
      'nurses_list_subtitle': 'جميع الممرضات في هذا المستشفى.',
      'hospital_profile': 'ملف المستشفى',
      'hospital_profile_subtitle': 'هوية المؤسسة',
      'open_full_hospital_profile': 'فتح ملف المستشفى الكامل',
      'admin_settings_subtitle': 'خيارات الحساب ولوحة التحكم',
      'refresh_data': 'تحديث البيانات',
      'refresh_data_subtitle': 'إعادة تحميل المعلومات',
      'hospital_profile_settings_subtitle': 'عرض تفاصيل المستشفى',
      'logout_admin_subtitle': 'تسجيل الخروج من لوحة التحكم',
      'hospital_id_label': 'معرّف المستشفى',
      'hospital_label': 'المستشفى',
      'admin_label': 'المدير',

      // Doctor screen
      'specialty': 'التخصص',
      'general': 'عام',
      'clinical_work': 'العمل الإكلينيكي',
      'assigned_cases': 'الحالات المكلّفة',
      'requests_and_notes': 'الطلبات والملاحظات',
      'scan_patient_qr': 'مسح QR المريض',
      'critical_queue': 'قائمة الحالات الحرجة',
      'no_critical_cases': 'لا توجد حالات حرجة',
      'institution_status': 'حالة المؤسسة',
      'doctor_profile': 'ملف الطبيب',
      'approval_status': 'حالة الموافقة',
      'role_label': 'الدور',
      'staff_id_label': 'رقم الموظف',
      'approval_label': 'الموافقة',
      'patients_label': 'المرضى',
      'urgent_label': 'عاجل',
      'requests_menu': 'الطلبات',
      'doctor_profile_subtitle': 'الهوية وبيانات المستشفى والتسجيل',
      'doctor_settings_subtitle': 'خيارات حساب الطبيب والوصول للنظام',
      'clinical_work_subtitle': 'الحالات المفتوحة والملاحظات الإكلينيكية',
      'assigned_cases_subtitle': 'إدارة حالاتك المكلّفة',
      'requests_and_notes_subtitle': 'طلبات المريض وملاحظات المتابعة',
      'scan_patient_qr_subtitle': 'اربط مريضًا بمسح رمز QR الخاص به',
      'critical_queue_subtitle': 'حالات الطوارئ والأولوية العاجلة',
      'no_critical_cases_subtitle': 'جميع المرضى في حالة مستقرة',
      'doctor_requests_subtitle': 'طلبات الطبيب المفتوحة والمتابعة',
      'institution_status_subtitle': 'ملخص دور الطبيب والتسجيل بالمستشفى',

      // Nurse / Staff shared
      'nursing_work': 'العمل التمريضي',
      'staff_work': 'العمل الوظيفي',
      'my_patients': 'مرضاي',
      'active_cases_label': 'الحالات النشطة',
      'assigned_patients_label': 'المرضى المكلّفون',
      'nurse_profile': 'ملف الممرضة',
      'staff_profile': 'ملف الموظف',
      'parent_profile': 'ملف ولي الأمر',
      'open_cases': 'الحالات المفتوحة',
      'nurse_overview_subtitle': 'ملخص لوحة التحكم للممرضة',
      'nursing_work_subtitle': 'الأدوات والإجراءات الرئيسية للممرضة',
      'nurse_profile_subtitle': 'الهوية والقسم وتفاصيل التسجيل بالمستشفى',
      'nurse_settings_subtitle': 'خيارات حساب الممرضة',
      'nurse_scan_subtitle': 'اربط مريضًا بمسح رمز QR أو إدخال معرّفه',
      'my_patients_subtitle': 'فتح قائمة المرضى المكلّفة بهم',
      'nurse_logout_subtitle': 'تسجيل الخروج من حساب الممرضة',
      'nurse_refresh_subtitle': 'إعادة تحميل بيانات لوحة التحكم',
      'staff_overview_subtitle': 'ملخص لوحة التحكم والحالات النشطة',
      'staff_work_subtitle': 'الأدوات والإجراءات الرئيسية للموظف',
      'staff_profile_subtitle': 'الهوية والقسم وتفاصيل التسجيل بالمستشفى',
      'staff_settings_subtitle': 'خيارات حساب الموظف',
      'staff_logout_subtitle': 'تسجيل الخروج من حساب الموظف',
      'staff_refresh_subtitle': 'إعادة تحميل بيانات لوحة التحكم',
      'staff_scan_subtitle': 'اربط مريضًا بمسح رمز QR أو إدخال معرّفه',
      'staff_patients_subtitle': 'فتح قائمة المرضى المكلّفين لهذا الموظف',

      // Parent screen
      'linked_patients': 'المرضى المرتبطون',
      'no_linked_patients': 'لا يوجد مرضى مرتبطون بعد',
      'scan_to_link': 'امسح QR لربط مريض',
      'view_patient': 'عرض المريض',
      'unlink': 'إلغاء الربط',
      'unlink_confirm': 'هل تريد إزالة هذا المريض من قائمتك؟',
      'parent_dashboard': 'لوحة تحكم ولي الأمر',
      'family_monitoring': 'متابعة الأسرة',
      'parent_track_subtitle': 'تتبعي حالة أطفالك والتنبيهات والحالة الصحية اليومية',
      'family_follow_up': 'حساب متابعة عائلي',
      'children': 'الأطفال',
      'notifications': 'الإشعارات',
      'enabled': 'مفعّل',
      'disabled': 'معطّل',
      'critical_only': 'الحرجة فقط',
      'children_status': 'حالة الأطفال',
      'scan_qr': 'مسح QR',
      'link_patient_subtitle': 'ربط حساب مريض',
      'critical_cases_first': 'الحالات الحرجة أولاً',
      'medical_pdf_subtitle': 'ملف PDF الطبي / الملخصات',
      'call_doctor_subtitle': 'الاتصال برسالة للطبيب',
      'profile_preferences_subtitle': 'الملف الشخصي والتفضيلات',
      'report_button': 'تقرير',
      'no_linked_children': 'لا يوجد أطفال مرتبطون بعد',
      'no_linked_children_desc': 'بمجرد ربط مريض بهذا الحساب، سيظهر ملف الطفل هنا.',
      'follow_up_profile': 'ملف المتابعة',
      'real_time_follow_up': 'متابعة فورية',
      'linked': 'مرتبط',
    },
  };

  String translate(String key) {
    const englishOverrides = {
      'medical_profile': 'Medical Profile',
      'weight': 'Weight',
      'height': 'Height',
      'blood_type': 'Blood Type',
      'chronic_diseases': 'Chronic Diseases',
      'allergies': 'Allergies',
      'emergency_contact': 'Emergency Contact',
      'contact_name': 'Contact Name',
      'contact_phone': 'Contact Phone',
      'emergency_phone': 'Emergency Phone',
      'national_id': 'National ID',
      'relation': 'Relation',
      'date_of_birth': 'Date of Birth',
      'enable_notifications': 'Enable Notifications',
      'critical_alerts_only': 'Critical Alerts Only',
      'welcome_subtitle': 'Smart monitoring for patients and care teams',
      'welcome_body':
          'Follow vitals, reports, alerts, QR access, and hospital workflows in one place.',
      'medication_reminders': 'Medication Reminders',
      'current': 'Current',
      'schedule': 'Schedule',
      'history': 'History',
      'active_medications': 'Active',
      'stopped_discontinued': 'Stopped',
      'prn_medications': 'PRN',
      'upcoming_doses': 'Upcoming',
      'missed': 'Missed',
      'active': 'Active',
      'stopped': 'Stopped',
      'completed': 'Completed',
      'prn': 'PRN',
      'route': 'Route',
      'all_routes': 'All routes',
      'all_doctors': 'All doctors',
      'oral': 'Oral',
      'injection': 'Injection',
      'topical': 'Topical',
      'inhaler': 'Inhaler',
      'drops': 'Drops',
      'add_medication': 'Add Medication',
      'edit_medication': 'Edit Medication',
      'medication_name': 'Medication name',
      'dosage': 'Dosage',
      'frequency': 'Frequency',
      'required': 'Required',
      'not_set': 'Not set',
      'search_medications': 'Search medications',
      'no_matching_medications': 'No matching medications',
      'last_dose': 'Last dose',
      'next_dose': 'Next dose',
      'stored_at': 'Stored at',
      'stored_at_hint': 'Stored at: fridge / bedside / pharmacy',
      'pickup_location': 'Pickup location',
      'patient_has_medication': 'Patient has medication',
      'mark_taken': 'Mark taken',
      'stop': 'Stop',
      'stop_medication': 'Stop medication',
      'stop_reason': 'Reason for stopping',
      'refill_request': 'Refill request',
      'refill_requested': 'Refill request saved',
      'view_history': 'View history',
      'today_schedule': "Today's schedule",
      'no_scheduled_doses': 'No scheduled doses',
      'soon': 'Soon',
      'upcoming': 'Upcoming',
      'taken_or_due': 'Taken / due',
      'marked_as_taken': 'Marked as taken',
      'updated': 'Updated',
      'no_medication_history': 'No medication history yet',
      'no_medication_alerts': 'No medication alerts',
      'warning': 'Warning',
      'allergy_alert': 'Allergy alert',
      'matches_allergy': 'matches allergy',
      'possible_duplicate': 'Possible duplicate',
      'appears_more_than_once': 'appears more than once',
      'indication': 'Indication',
      'instructions': 'Instructions',
      'start_date': 'Start date',
      'end_date': 'End date',
      'prescribed_by': 'Prescribed by',
      'contraindications_allergy_warning':
          'Contraindications or allergy warning',
      'prn_medication': 'PRN medication',
      'dose_times': 'Dose times',
      'add_time': 'Add time',
      'medication_added': 'Medication added',
      'medication_updated': 'Medication updated',
      'failed_to_save_medication': 'Failed to save medication',
      'no_medications_added_yet': 'No medications added yet',
    };

    if (locale.languageCode == 'ar') {
      const arabicOverrides = {
        'app_name': 'SmartCare',
        'welcome': 'مرحبا',
        'welcome_back': 'أهلا بعودتك',
        'welcome_subtitle': 'متابعة صحية ذكية للمريض والطاقم الطبي',
        'welcome_body':
            'تابعي القياسات والتقارير والتنبيهات وQR ومسار المستشفى في مكان واحد.',
        'start_here': 'ابدأ من هنا',
        'choose_login_or_signup':
            'اختاري تسجيل الدخول أو إنشاء حساب جديد للمتابعة.',
        'choose_role': 'اختيار الدور',
        'select_how_to_use': 'اختاري طريقة استخدام SmartCare',
        'language': 'اللغة',
        'arabic': 'العربية',
        'english': 'الإنجليزية',
        'login': 'تسجيل الدخول',
        'signup': 'إنشاء حساب',
        'create_account': 'إنشاء حساب',
        'registration': 'التسجيل',
        'email': 'البريد الإلكتروني',
        'password': 'كلمة المرور',
        'full_name': 'الاسم الكامل',
        'phone': 'رقم الهاتف',
        'patient': 'مريض',
        'parent': 'ولي أمر',
        'doctor': 'دكتور',
        'nurse': 'ممرضة',
        'staff': 'طاقم',
        'hospital_admin': 'مدير المستشفى',
        'hospital_admin_desc': 'تسجيل المستشفى وإدارة الموافقات',
        'doctor_desc': 'طبيب تابع للمستشفى',
        'nurse_desc': 'ممرضة تابعة للمستشفى',
        'staff_desc': 'طاقم دعم داخل المستشفى',
        'patient_desc': 'قياسات وتنبيهات وتقارير ومتابعة',
        'parent_desc': 'متابعة حالة المريض',
        'patient_intake': 'بيانات المريض',
        'profile': 'الملف الشخصي',
        'institution': 'المؤسسة',
        'hospital_id': 'معرف المستشفى',
        'medical_profile': 'الملف الطبي',
        'weight': 'الوزن',
        'height': 'الطول',
        'blood_type': 'فصيلة الدم',
        'chronic_diseases': 'الأمراض المزمنة',
        'allergies': 'الحساسية',
        'emergency_contact': 'جهة اتصال الطوارئ',
        'contact_name': 'اسم جهة الاتصال',
        'contact_phone': 'هاتف جهة الاتصال',
        'emergency_phone': 'هاتف الطوارئ',
        'national_id': 'الرقم القومي',
        'relation': 'صلة القرابة',
        'date_of_birth': 'تاريخ الميلاد',
        'gender': 'النوع',
        'date': 'التاريخ',
        'optional': 'اختياري',
        'save': 'حفظ',
        'save_continue': 'حفظ ومتابعة',
        'loading': 'جاري التحميل',
        'department': 'القسم',
        'employee_id': 'الرقم الوظيفي',
        'license_number': 'رقم الترخيص',
        'submit_registration': 'إرسال التسجيل',
        'staff_registration': 'تسجيل الطاقم',
        'hospital_setup': 'إعداد المستشفى',
        'admin_full_name': 'اسم المدير الكامل',
        'hospital_name': 'اسم المستشفى',
        'city': 'المدينة',
        'address': 'العنوان',
        'description': 'الوصف',
        'complete_setup': 'إكمال الإعداد',
        'enable_notifications': 'تفعيل الإشعارات',
        'critical_alerts_only': 'التنبيهات الحرجة فقط',
        'update_my_data': 'تحديث بياناتي',
        'update_my_data_desc': 'تعديل البيانات الشخصية والطوارئ والملف الطبي',
        'medication_reminders': 'تذكيرات الأدوية',
        'current': 'الحالية',
        'schedule': 'الجدول',
        'history': 'السجل',
        'all': 'الكل',
        'active_medications': 'نشطة',
        'stopped_discontinued': 'متوقفة',
        'prn_medications': 'عند اللزوم',
        'upcoming_doses': 'الجرعات القادمة',
        'missed': 'فائتة',
        'active': 'نشط',
        'stopped': 'متوقف',
        'completed': 'مكتمل',
        'prn': 'عند اللزوم',
        'route': 'طريقة الاستخدام',
        'all_routes': 'كل الطرق',
        'all_doctors': 'كل الأطباء',
        'oral': 'عن طريق الفم',
        'injection': 'حقن',
        'topical': 'موضعي',
        'inhaler': 'بخاخ',
        'drops': 'قطرات',
        'add_medication': 'إضافة دواء',
        'edit_medication': 'تعديل الدواء',
        'medication_name': 'اسم الدواء',
        'dosage': 'الجرعة',
        'frequency': 'عدد المرات',
        'required': 'مطلوب',
        'not_set': 'غير محدد',
        'search_medications': 'ابحث باسم الدواء',
        'no_matching_medications': 'لا توجد أدوية مطابقة',
        'last_dose': 'آخر جرعة',
        'next_dose': 'الجرعة القادمة',
        'stored_at': 'مكان الحفظ',
        'stored_at_hint': 'مكان الحفظ: الثلاجة / بجانب السرير / الصيدلية',
        'pickup_location': 'مكان الاستلام',
        'patient_has_medication': 'الدواء مع المريض',
        'mark_taken': 'تم أخذها',
        'stop': 'إيقاف',
        'stop_medication': 'إيقاف الدواء',
        'stop_reason': 'سبب الإيقاف',
        'refill_request': 'طلب إعادة صرف',
        'refill_requested': 'تم تسجيل طلب إعادة الصرف',
        'view_history': 'عرض السجل',
        'today_schedule': 'جدول اليوم',
        'no_scheduled_doses': 'لا توجد جرعات مجدولة',
        'soon': 'قريبًا',
        'upcoming': 'قادمة',
        'taken_or_due': 'تمت / مستحقة',
        'marked_as_taken': 'تم تسجيل الجرعة',
        'updated': 'تم التحديث',
        'no_medication_history': 'لا يوجد سجل أدوية بعد',
        'no_medication_alerts': 'لا توجد تنبيهات أدوية',
        'warning': 'تحذير',
        'allergy_alert': 'تنبيه حساسية',
        'matches_allergy': 'يطابق حساسية',
        'possible_duplicate': 'تكرار محتمل',
        'appears_more_than_once': 'موجود أكثر من مرة',
        'indication': 'سبب الاستخدام',
        'instructions': 'التعليمات',
        'start_date': 'تاريخ البداية',
        'end_date': 'تاريخ النهاية',
        'prescribed_by': 'وصفه',
        'contraindications_allergy_warning': 'تحذير حساسية أو موانع استخدام',
        'prn_medication': 'دواء عند اللزوم',
        'dose_times': 'مواعيد الجرعات',
        'add_time': 'إضافة وقت',
        'medication_added': 'تمت إضافة الدواء',
        'medication_updated': 'تم تحديث الدواء',
        'failed_to_save_medication': 'فشل حفظ الدواء',
        'no_medications_added_yet': 'لم تتم إضافة أدوية بعد',
      };
      final value = arabicOverrides[key];
      if (value != null) return value;
    }

    final englishValue = englishOverrides[key];
    if (englishValue != null) {
      return englishValue;
    }

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
      case 'attention needed':
        return translate('attention_needed');
      case 'high risk':
        return translate('high_risk');
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
