import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone init
    tzdata.initializeTimeZones(); // This line is correct
    tz.setLocalLocation(tz.getLocation(localTz as String));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  NotificationDetails _details({String? channelId, String? channelName}) {
    final android = AndroidNotificationDetails(
      channelId ?? 'smartcare_channel',
      channelName ?? 'SmartCare Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(id, title, body, _details());
  }

  /// Schedule a DAILY medication reminder at fixed hour/min
  /// id must be stable (unique per med & time)
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(channelId: 'meds_channel', channelName: 'Medication Reminders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Helper: make a stable notification id from text + time
  int makeId(String seed) {
    // 0..2^31-1
    return seed.hashCode & 0x7fffffff;
  }

  Future<void> showNow({required int id, required String title, required body}) async {}

  void show(String s, String t) {}
}

class localTz {
}
