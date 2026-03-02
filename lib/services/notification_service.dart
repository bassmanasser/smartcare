import 'package:flutter/src/material/time.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. تهيئة بيانات التوقيت
    tz.initializeTimeZones();
    
    // ✅ التصحيح: تعيين التوقيت يدوياً للقاهرة (أو UTC) لتجنب خطأ الـ Null
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    } catch (e) {
      // لو حصل أي خطأ، نستخدم UTC كاحتياطي
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. إعدادات الأندرويد
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 3. تجميع الإعدادات
    const settings = InitializationSettings(android: androidSettings);

    // 4. التشغيل الفعلي
    await _plugin.initialize(settings);
    
    _isInitialized = true;
  }

  // --- دالة لإظهار إشعار فوري (SOS أو Fall Detection) ---
  Future<void> show(String title, String body) async {
    await showInstant(id: 0, title: title, body: body);
  }
  
  Future<void> showNow({required int id, required String title, required String body}) async {
    await showInstant(id: id, title: title, body: body);
  }

  Future<void> showInstant({required int id, required String title, required String body}) async {
     const androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // Id
      'High Importance Notifications', // Name
      channelDescription: 'Notifications for SOS and Falls',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  // --- دالة لجدولة الأدوية ---
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Reminders to take medicine',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // للتكرار اليومي بنفس التوقيت
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Helper لتوليد ID رقمي
  int makeId(String uniqueStr) {
    return uniqueStr.hashCode;
  }

  static Future<void> scheduleMedicationReminders({required String medicationId, required String name, required List<TimeOfDay> times}) async {}
}